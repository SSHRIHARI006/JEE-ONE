from datetime import datetime, timezone
from typing import List

from logic.models.ambulance_model import AmbulanceModel
from logic.models.patient_model import CoordinatesModel


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_ambulance_data() -> List[AmbulanceModel]:
    return [
        AmbulanceModel(ambulance_id="A001", current_location=CoordinatesModel(latitude=12.9710, longitude=77.5940), status="available", assigned_case_id="", last_updated_timestamp=_now_iso()),
        AmbulanceModel(ambulance_id="A002", current_location=CoordinatesModel(latitude=12.9650, longitude=77.6100), status="available", assigned_case_id="", last_updated_timestamp=_now_iso()),
        AmbulanceModel(ambulance_id="A003", current_location=CoordinatesModel(latitude=12.9400, longitude=77.6200), status="busy", assigned_case_id="case-locked", last_updated_timestamp=_now_iso()),
        AmbulanceModel(ambulance_id="A004", current_location=CoordinatesModel(latitude=12.9900, longitude=77.5700), status="available", assigned_case_id="", last_updated_timestamp=_now_iso()),
        AmbulanceModel(ambulance_id="A005", current_location=CoordinatesModel(latitude=12.9150, longitude=77.6450), status="assigned", assigned_case_id="case-active", last_updated_timestamp=_now_iso()),
        AmbulanceModel(ambulance_id="A006", current_location=CoordinatesModel(latitude=13.0150, longitude=77.6060), status="available", assigned_case_id="", last_updated_timestamp=_now_iso()),
        AmbulanceModel(ambulance_id="A007", current_location=CoordinatesModel(latitude=12.8820, longitude=77.6010), status="available", assigned_case_id="", last_updated_timestamp=_now_iso()),
        AmbulanceModel(ambulance_id="A008", current_location=CoordinatesModel(latitude=12.9570, longitude=77.7010), status="busy", assigned_case_id="case-transfer", last_updated_timestamp=_now_iso()),
    ]
