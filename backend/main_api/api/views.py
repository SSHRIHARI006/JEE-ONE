import logging
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
    """
    Primary emergency intake endpoint.

    Accepts a natural-language description of the emergency, runs it through
    the agent pipeline (or Haversine fallback), optionally signs a blockchain
    block, and returns the full result.
    """

    def post(self, request):
        try:
            patients = request.data.get("patients")

            # Batch mode: {"patients": [{"input_text": "...", "source_type": "..."}, ...]}
            if isinstance(patients, list):
                if not patients:
                    return Response({"error": "patients list cannot be empty"}, status=400)
                source_type = request.data.get("source_type", "public")
                result = run_batch_workflow(patients, default_source_type=source_type)
                return Response(result, status=200)

            input_text = request.data.get("input_text")
            if not input_text:
                return Response({"error": "input_text or patients is required"}, status=400)

            source_type = request.data.get("source_type", "public")
            patient_id = request.data.get("patient_id")
            location = request.data.get("location") or {}
            latitude = location.get("latitude")
            longitude = location.get("longitude")

            # Patient-aware mode: {"patient_id": "...", "input_text": "...", "vitals": {...}, "location": {...}}
            # Fetches blockchain history and feeds it to the diagnostic agent.
            if patient_id:
                vitals = request.data.get("vitals") or {}
                result = run_patient_workflow(
                    patient_id, input_text, vitals, source_type,
                    latitude=latitude, longitude=longitude,
                )
            else:
                # Anonymous single mode: {"input_text": "..."}
                result = run_workflow(input_text, source_type, latitude=latitude, longitude=longitude)

            # If the agent confirmed a routing decision, sign it on-chain
            if "DECISION_MADE" in result.get("events", []):
                try:
                    # Pull identifiers — agent may return them in slightly
                    # different shapes depending on the pipeline used.
                    rec = result.get("selected_recommendation", {})
                    case_id = rec.get("case_id") or result.get("case_id", "")
                    hospital_id = (
                        rec.get("hospital_id")
                        or result.get("selected_hospital", {}).get("id", "")
                    )
                    severity = result.get("case_summary", {}).get("severity", 0)

                    block = sign_decision_block(case_id, hospital_id, severity)
                    result["blockchain"] = block

                    # Persist the block reference to EventLogs (best-effort)
                    try:
                        case_obj = EmergencyCases.objects.get(case_id=case_id)
                        EventLogs.objects.create(
                            event_id="blk_" + block["block_hash"][:44],
                            case=case_obj,
                            event_type="BLOCKCHAIN_SIGNED",
                            timestamp=datetime.now(timezone.utc),
                        )
                    except EmergencyCases.DoesNotExist:
                        logger.warning(
                            f"[JIVAN] Case {case_id} not in DB — blockchain event log skipped."
                        )
                    except Exception as db_exc:
                        logger.warning(
                            f"[JIVAN] EventLog write failed for case {case_id}: {db_exc}"
                        )

                except Exception as chain_exc:
                    # Blockchain signing must never crash the SOS response
                    logger.warning(f"[JIVAN] Blockchain signing skipped: {chain_exc}")

            return Response(result, status=200)

        except Exception as exc:
            # Truly unrecoverable — should essentially never happen
            logger.error(f"[JIVAN] SOSView unrecoverable error: {exc}")
            return Response({"error": "Internal server error", "detail": str(exc)}, status=500)


# ---------------------------------------------------------------------------
# GET /api/hospitals/
# ---------------------------------------------------------------------------

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
