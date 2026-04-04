import logging
import os
import json
from datetime import datetime, timezone

from rest_framework.views import APIView
from rest_framework.response import Response

from .models import Hospitals, EmergencyCases, EventLogs, Ambulances, AmbulanceAssignment
from .serializer import (
    HospitalSerializer, EmergencyCaseSerializer,
    AmbulanceSerializer, ActiveCaseSerializer,
)
from .blockchain import sign_decision_block
from .workflow_wrapper import run_workflow, run_batch_workflow, run_patient_workflow, haversine_km

logger = logging.getLogger('jivan')


# ---------------------------------------------------------------------------
# POST /api/sos/
# ---------------------------------------------------------------------------

class SOSView(APIView):
    def post(self, request):
        # 1. INITIAL INTAKE DEBUG
        logger.info("================ SOS INTAKE START ================")
        logger.info(f"[DEBUG] Raw Payload keys: {list(request.data.keys())}")
        
        try:
            patients = request.data.get("patients")

            # --- BATCH MODE ---
            if isinstance(patients, list):
                logger.info(f"[DEBUG] Batch Mode: Processing {len(patients)} patients")
                source_type = request.data.get("source_type", "public")
                result = run_batch_workflow(patients, default_source_type=source_type)
                return Response(result, status=200)

            # --- SINGLE MODE DATA EXTRACTION ---
            input_text = request.data.get("input_text")
            if not input_text:
                logger.error("[DEBUG] Missing input_text in payload")
                return Response({"error": "input_text or patients is required"}, status=400)

            source_type = request.data.get("source_type", "public")
            patient_id = request.data.get("patient_id")
            vitals = request.data.get("vitals") or {}
            location = request.data.get("location") or {}
            lat, lon = location.get("latitude"), location.get("longitude")
            
            # --- SCENE CONTEXT DEBUG ---
            scene_context = request.data.get("scene_context")
            logger.info(f"[DEBUG] Input Text: {input_text[:50]}...")
            logger.info(f"[DEBUG] Patient ID: {patient_id} | Vitals: {vitals}")
            logger.info(f"[DEBUG] Location: Lat {lat}, Lon {lon}")

            if scene_context:
                if isinstance(scene_context, dict):
                    logger.info(f"[DEBUG] Scene Context received: {list(scene_context.keys())}")
                else:
                    logger.error(f"[DEBUG] Malformed Scene Context (type: {type(scene_context)}). Expected DICT.")
                    scene_context = None
            else:
                logger.warning("[DEBUG] No scene_context found in this request.")

            # --- WORKFLOW EXECUTION ---
            if patient_id:
                logger.info(f"[DEBUG] Executing run_patient_workflow for {patient_id}")
                result = run_patient_workflow(
                    patient_id, input_text, vitals, source_type,
                    latitude=lat, longitude=lon, scene_context=scene_context
                )
            else:
                logger.info("[DEBUG] Executing anonymous run_workflow")
                result = run_workflow(
                    input_text, source_type, latitude=lat, longitude=lon, 
                    scene_context=scene_context
                )

            # --- FALLBACK DETECTION ---
            if result.get("fallback") is True:
                logger.error(f"[CRITICAL] AI PIPELINE FAILED. Reason: {result.get('reason', 'Unknown')}")
                logger.error(f"[DEBUG] Pipeline Events: {result.get('events')}")
            else:
                logger.info(f"[SUCCESS] AI Pipeline returned successfully. Urgency: {result.get('urgency')}")

            # --- PERSISTENCE: SCENE CONTEXT ---
            if scene_context:
                try:
                    rec = result.get("selected_recommendation", {})
                    _case_id = rec.get("case_id") or result.get("case_id", "")
                    if _case_id:
                        rows = EmergencyCases.objects.filter(case_id=_case_id).update(
                            scene_context=json.dumps(scene_context)
                        )
                        logger.info(f"[DEBUG] DB update scene_context for {_case_id}: {rows} row(s) updated.")
                except Exception as sc_exc:
                    logger.error(f"[DEBUG] Database update failed for scene_context: {sc_exc}")

            # --- PERSISTENCE: BLOCKCHAIN ---
            if "DECISION_MADE" in result.get("events", []):
                try:
                    rec = result.get("selected_recommendation", {})
                    case_id = rec.get("case_id") or result.get("case_id", "")
                    hospital_id = rec.get("hospital_id") or result.get("selected_hospital", {}).get("id", "")
                    severity = result.get("case_summary", {}).get("severity", 0)

                    logger.info(f"[DEBUG] Signing blockchain for Case: {case_id} -> Hospital: {hospital_id}")
                    block = sign_decision_block(case_id, hospital_id, severity)
                    result["blockchain"] = block

                    # Log Block to DB
                    case_obj = EmergencyCases.objects.get(case_id=case_id)
                    EventLogs.objects.create(
                        event_id="blk_" + block["block_hash"][:44],
                        case=case_obj,
                        event_type="BLOCKCHAIN_SIGNED",
                        timestamp=datetime.now(timezone.utc),
                    )
                except Exception as chain_exc:
                    logger.warning(f"[DEBUG] Blockchain workflow non-fatal error: {chain_exc}")

            logger.info("================ SOS INTAKE END ================")
            return Response(result, status=200)

        except Exception as exc:
            logger.critical(f"[FATAL] SOSView Unrecoverable Crash: {exc}", exc_info=True)
            return Response({"error": "Internal server error", "detail": str(exc)}, status=500)

# ---------------------------------------------------------------------------
# GET /api/hospitals/
# ---------------------------------------------------------------------------

class SceneAnalysisView(APIView):
    """
    POST /api/analyze-scene/

    Accepts a base64-encoded scene photograph and returns structured clinical
    context extracted by Claude vision. This endpoint is called ONCE before
    submitting the SOS request — the returned JSON is passed as scene_context
    in the SOS body, keeping the main SOS call fast (no image bytes).

    Body:
        { "image_base64": "<base64 string>", "media_type": "image/jpeg" }

    Response:
        {
            "severity_estimate": 8,
            "mechanism_of_injury": "high-speed vehicle collision",
            "patient_count": 2,
            "consciousness_estimate": "at least one victim unresponsive",
            "visible_injuries": ["head trauma", "road rash"],
            "blood_loss": { "present": true, "severity": "significant", "description": "..." },
            "scene_hazards": ["vehicle debris", "traffic risk"],
            "vehicle_damage_severity": "severe",
            "recommended_resources": ["trauma surgeon", "ICU"],
            "scene_summary": "..."
        }
    """

    def post(self, request):
        image_base64 = request.data.get("image_base64")
        if not image_base64:
            return Response({"error": "image_base64 is required"}, status=400)

        media_type = request.data.get("media_type", "image/jpeg")
        allowed_types = {"image/jpeg", "image/png", "image/gif", "image/webp"}
        if media_type not in allowed_types:
            media_type = "image/jpeg"

        try:
            _AGENT_WORKFLOW_PATH = os.path.abspath(
                os.path.join(os.path.dirname(__file__), '..', '..', '..', 'AGENT-WORKFLOW')
            )
            import sys
            if _AGENT_WORKFLOW_PATH not in sys.path:
                sys.path.insert(0, _AGENT_WORKFLOW_PATH)

            from logic.utils.claude_client import extract_scene_context
            result = extract_scene_context(image_base64, media_type=media_type)

            if not result.get("scene_summary"):
                return Response(
                    {"error": "Scene analysis failed — Claude could not extract data from this image."},
                    status=422,
                )

            logger.info(
                f"[SCENE] Analysis complete — severity {result.get('severity_estimate')}, "
                f"mechanism: {result.get('mechanism_of_injury')}"
            )
            return Response(result, status=200)

        except Exception as exc:
            logger.error(f"[SCENE] SceneAnalysisView error: {exc}")
            return Response({"error": "Scene analysis failed", "detail": str(exc)}, status=500)


class HospitalsView(APIView):
    """Return all hospitals with their live dynamic status."""

    def get(self, request):
        try:
            hospitals = Hospitals.objects.select_related('hospitaldynamicstatus').all()
            serializer = HospitalSerializer(hospitals, many=True)
            count = hospitals.count()
            logger.info(f"[JIVAN] Hospitals fetched: {count} records")
            return Response(serializer.data, status=200)
        except Exception as exc:
            logger.error(f"[JIVAN] HospitalsView error: {exc}")
            return Response({"error": "Could not fetch hospitals", "detail": str(exc)}, status=500)


# ---------------------------------------------------------------------------
# GET /api/cases/<case_id>/
# ---------------------------------------------------------------------------

class CaseDetailView(APIView):
    """Return an emergency case record together with its triage data."""

    def get(self, request, case_id: str):
        try:
            case = EmergencyCases.objects.select_related('triage').get(case_id=case_id)
            serializer = EmergencyCaseSerializer(case)
            return Response(serializer.data, status=200)
        except EmergencyCases.DoesNotExist:
            return Response({"error": f"Case '{case_id}' not found"}, status=404)
        except Exception as exc:
            logger.error(f"[JIVAN] CaseDetailView error for {case_id}: {exc}")
            return Response({"error": "Could not fetch case", "detail": str(exc)}, status=500)


# ---------------------------------------------------------------------------
# GET /api/cases/
# ---------------------------------------------------------------------------

class CasesListView(APIView):
    """Return all emergency cases enriched with triage, hospitals, and ambulance."""

    def get(self, request):
        try:
            cases = (
                EmergencyCases.objects
                .select_related('triage', 'patient')
                .prefetch_related(
                    'recommendations_set__hospital__hospitaldynamicstatus',
                    'ambulanceassignment__ambulance',
                )
                .order_by('-timestamp')[:50]
            )
            serializer = ActiveCaseSerializer(cases, many=True)
            return Response(serializer.data, status=200)
        except Exception as exc:
            logger.error(f"[JIVAN] CasesListView error: {exc}")
            return Response({"error": "Could not fetch cases", "detail": str(exc)}, status=500)


# ---------------------------------------------------------------------------
# GET /api/ambulances/
# ---------------------------------------------------------------------------

class AmbulancesView(APIView):
    """Return all ambulances with their current position and status."""

    def get(self, request):
        try:
            ambulances = Ambulances.objects.all()
            serializer = AmbulanceSerializer(ambulances, many=True)
            return Response(serializer.data, status=200)
        except Exception as exc:
            logger.error(f"[JIVAN] AmbulancesView error: {exc}")
            return Response({"error": "Could not fetch ambulances", "detail": str(exc)}, status=500)


# ---------------------------------------------------------------------------
# POST /api/ambulances/dispatch/
# ---------------------------------------------------------------------------

class DispatchView(APIView):
    """
    Phase 1 Smart Dispatch — find the nearest available ambulance to a
    patient and assign it.

    Body: { "case_id": "...", "latitude": 18.52, "longitude": 73.81 }
    """

    def post(self, request):
        case_id = request.data.get("case_id")
        patient_lat = request.data.get("latitude")
        patient_lng = request.data.get("longitude")

        if not all([case_id, patient_lat is not None, patient_lng is not None]):
            return Response(
                {"error": "case_id, latitude, and longitude are required"}, status=400
            )

        try:
            case_obj = EmergencyCases.objects.get(case_id=case_id)
        except EmergencyCases.DoesNotExist:
            return Response({"error": f"Case '{case_id}' not found"}, status=404)

        available = list(Ambulances.objects.filter(status="available"))
        if not available:
            return Response({"error": "No available ambulances at this time"}, status=503)

        patient_lat = float(patient_lat)
        patient_lng = float(patient_lng)

        nearest = min(
            available,
            key=lambda a: haversine_km(patient_lat, patient_lng, a.latitude, a.longitude),
        )
        dist_km = haversine_km(patient_lat, patient_lng, nearest.latitude, nearest.longitude)
        eta_minutes = max(int((dist_km / 35.0) * 60), 2)

        nearest.status = "dispatched"
        nearest.last_updated_timestamp = datetime.now(timezone.utc)
        nearest.save()

        AmbulanceAssignment.objects.update_or_create(
            case=case_obj,
            defaults={"ambulance": nearest, "eta_to_patient": eta_minutes},
        )

        logger.info(
            f"[JIVAN] Dispatched {nearest.ambulance_id} to case {case_id} "
            f"— dist {dist_km:.2f} km, ETA {eta_minutes} min"
        )
        return Response(
            {
                "ambulance_id": nearest.ambulance_id,
                "eta_to_patient": eta_minutes,
                "distance_km": round(dist_km, 2),
                "ambulance_lat": nearest.latitude,
                "ambulance_lng": nearest.longitude,
                "status": "dispatched",
            },
            status=200,
        )


# ---------------------------------------------------------------------------
# PATCH /api/ambulances/<ambulance_id>/location/
# ---------------------------------------------------------------------------

class AmbulanceLocationView(APIView):
    """
    Update an ambulance's GPS position (and optionally its status).
    Called periodically by the EMT device as it moves.

    Body: { "latitude": 18.52, "longitude": 73.81, "status": "available" }
    """

    def patch(self, request, ambulance_id: str):
        latitude = request.data.get("latitude")
        longitude = request.data.get("longitude")

        if latitude is None or longitude is None:
            return Response({"error": "latitude and longitude are required"}, status=400)

        try:
            amb = Ambulances.objects.get(ambulance_id=ambulance_id)
        except Ambulances.DoesNotExist:
            return Response({"error": f"Ambulance '{ambulance_id}' not found"}, status=404)

        amb.latitude = float(latitude)
        amb.longitude = float(longitude)
        amb.last_updated_timestamp = datetime.now(timezone.utc)

        new_status = request.data.get("status")
        if new_status:
            amb.status = new_status

        amb.save()
        return Response({"success": True, "ambulance_id": ambulance_id}, status=200)
