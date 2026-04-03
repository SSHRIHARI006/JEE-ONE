from datetime import datetime, timezone
from typing import Optional

from logic.models.ambulance_model import AmbulanceAssignmentModel, AmbulanceModel
from logic.models.patient_model import CoordinatesModel
from logic.services.routing_service import compute_distance_km, compute_eta_minutes
from logic.utils.db_store import load_ambulances


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def find_nearest_available_ambulance(
    patient_location: CoordinatesModel,
    exclude_ids: Optional[set] = None,
) -> Optional[AmbulanceModel]:
    rows = load_ambulances()
    ambulances = [
        AmbulanceModel(
            ambulance_id=str(row["ambulance_id"]),
            current_location=CoordinatesModel(
                latitude=float(row.get("latitude") or 0.0),
                longitude=float(row.get("longitude") or 0.0),
            ),
            status=str(row.get("status") or "available"),
            assigned_case_id="",
            last_updated_timestamp=str(row.get("last_updated_timestamp") or ""),
        )
        for row in rows
    ]
    available = [
        a for a in ambulances
        if a.status == "available" and (exclude_ids is None or a.ambulance_id not in exclude_ids)
    ]
    if not available:
        return None

    available.sort(
        key=lambda amb: compute_distance_km(amb.current_location, patient_location)
    )
    return available[0]


def assign_ambulance(
    case_id: str,
    patient_location: CoordinatesModel,
    exclude_ids: Optional[set] = None,
) -> Optional[AmbulanceAssignmentModel]:
    ambulance = find_nearest_available_ambulance(patient_location, exclude_ids=exclude_ids)
    if ambulance is None:
        return None

    distance = compute_distance_km(ambulance.current_location, patient_location)
    raw_eta = compute_eta_minutes(distance_km=distance, speed_kmph=40.0, traffic_level="medium")
    if distance <= 3.0:
        eta = min(max(raw_eta, 5), 10)
    elif distance <= 10.0:
        eta = min(max(raw_eta, 8), 20)
    else:
        eta = min(max(raw_eta, 20), 45)

    return AmbulanceAssignmentModel(
        case_id=case_id,
        ambulance_id=ambulance.ambulance_id,
        eta_to_patient=eta,
        status="dispatched",
        assigned_timestamp=_now_iso(),
    )
