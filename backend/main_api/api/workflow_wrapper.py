import os
import sys
import math
import logging

logger = logging.getLogger('jivan')

# ---------------------------------------------------------------------------
# Path injection — add AGENT-WORKFLOW so its modules are importable.
# __file__ lives at:  JEE-ONE/backend/main_api/api/workflow_wrapper.py
# AGENT-WORKFLOW is at: JEE-ONE/AGENT-WORKFLOW/
# Three parent directories up from api/ brings us to JEE-ONE/.
# ---------------------------------------------------------------------------
_AGENT_WORKFLOW_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..', '..', 'AGENT-WORKFLOW')
)
if _AGENT_WORKFLOW_PATH not in sys.path:
    sys.path.insert(0, _AGENT_WORKFLOW_PATH)

# Default incident location used by the Haversine fallback (Pune city centre)
_DEFAULT_LAT = 18.518
_DEFAULT_LON = 73.815


# ---------------------------------------------------------------------------
# Haversine distance helper
# ---------------------------------------------------------------------------

def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Return the great-circle distance in kilometres between two coordinates."""
    R = 6371.0  # Earth radius in km

    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)

    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


# ---------------------------------------------------------------------------
# Haversine fallback — used when the agent pipeline fails
# ---------------------------------------------------------------------------

def _haversine_fallback(input_text: str, source_type: str) -> dict:
    """
    Query all hospitals from the DB, rank by straight-line distance from the
    default location, and return a structured result that callers can use
    without depending on the agent pipeline.
    """
    # Import here to avoid circular import issues at module load time
    from .models import Hospitals

    hospitals = list(Hospitals.objects.select_related('hospitaldynamicstatus').all())

    ranked = []
    for h in hospitals:
        dist = haversine_km(_DEFAULT_LAT, _DEFAULT_LON, h.latitude, h.longitude)
        ranked.append({
            "hospital_id": h.hospital_id,
            "hospital_name": h.hospital_name,
            "distance_km": round(dist, 3),
            "latitude": h.latitude,
            "longitude": h.longitude,
        })

    # Nearest first
    ranked.sort(key=lambda x: x["distance_km"])
    nearest = ranked[0] if ranked else {}

    return {
        "fallback": True,
        "source_type": source_type,
        "input_text": input_text,
        "selected_hospital": {
            "id": nearest.get("hospital_id"),
            "name": nearest.get("hospital_name"),
            "distance_km": nearest.get("distance_km"),
        },
        "ranked_hospitals": ranked,
        "events": [],
        "message": "Agent pipeline unavailable — Haversine fallback activated.",
    }


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def run_workflow(input_text: str, source_type: str = 'public', latitude=None, longitude=None) -> dict:
    """
    Dispatch to the appropriate agent view and return the result dict.

    Falls back to Haversine-based hospital selection if the agent raises
    any exception at all.
    """
    try:
        if source_type == 'ambulance':
            from logic.views.medic_view import handle_medic_request
            result = handle_medic_request(input_text, latitude=latitude, longitude=longitude)

            hospital_id = (
                result.get("selected_recommendation", {}).get("hospital_id")
                or result.get("selected_hospital", {}).get("id")
                or "UNKNOWN"
            )
            logger.info(f"[JIVAN AGENT] Medic pipeline complete. Hospital: {hospital_id}")
        else:
            from logic.views.public_view import handle_public_request
            result = handle_public_request(input_text, latitude=latitude, longitude=longitude)

            severity = result.get("case_summary", {}).get("severity", "?")
            hospital_name = (
                result.get("selected_recommendation", {}).get("hospital_name")
                or result.get("selected_hospital", {}).get("name")
                or "UNKNOWN"
            )
            logger.info(
                f"[JIVAN AGENT] Triage Complete. Severity: {severity}. Routing to {hospital_name}."
            )

        return result

    except Exception as exc:
        import traceback
        logger.error(f"[JIVAN AGENT] Workflow failed: {exc}\n{traceback.format_exc()}")
        return _haversine_fallback(input_text, source_type)


def run_patient_workflow(patient_id: str, input_text: str, vitals: dict, source_type: str = 'public', latitude=None, longitude=None) -> dict:
    """
    Patient-aware workflow: fetches blockchain history for the patient, injects
    it into the pipeline so the diagnostic agent can correlate past events.
    """
    try:
        from .blockchain import get_patient_blockchain_history
        blockchain_history = get_patient_blockchain_history(patient_id)
    except Exception as exc:
        logger.warning(f"[JIVAN] Blockchain history fetch failed for {patient_id}: {exc}")
        blockchain_history = []

    try:
        if source_type == 'ambulance':
            from logic.views.medic_view import handle_medic_request
            result = handle_medic_request(input_text, blockchain_history=blockchain_history, latitude=latitude, longitude=longitude, vitals=vitals)
        else:
            from logic.views.public_view import handle_public_request
            result = handle_public_request(input_text, blockchain_history=blockchain_history, latitude=latitude, longitude=longitude, vitals=vitals)

        result["patient_id"] = patient_id
        result["blockchain_history_records"] = len(blockchain_history)
        return result

    except Exception as exc:
        import traceback
        logger.error(f"[JIVAN] Patient workflow failed for {patient_id}: {exc}\n{traceback.format_exc()}")
        fallback = _haversine_fallback(input_text, source_type)
        fallback["patient_id"] = patient_id
        fallback["blockchain_history_records"] = len(blockchain_history)
        return fallback


def run_batch_workflow(patients: list, default_source_type: str = 'public') -> dict:
    """
    Process a list of patients through the single-patient pipeline.

    Each item in `patients` must have an `input_text` field and an optional
    `source_type` field. Returns a summary + per-patient results array.
    """
    results = []
    for patient in patients:
        input_text = patient.get("input_text", "")
        source_type = patient.get("source_type", default_source_type)
        loc = patient.get("location") or {}
        latitude = loc.get("latitude")
        longitude = loc.get("longitude")
        result = run_workflow(input_text, source_type, latitude=latitude, longitude=longitude)
        results.append(result)

    return {
        "batch": True,
        "total": len(results),
        "results": results,
    }
