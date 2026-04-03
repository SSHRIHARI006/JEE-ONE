from typing import Literal

from pydantic import BaseModel, Field

from logic.models.patient_model import CoordinatesModel


class AmbulanceModel(BaseModel):
    ambulance_id: str
    current_location: CoordinatesModel = Field(default_factory=CoordinatesModel)
    status: Literal["available", "assigned", "busy"] = "available"
    assigned_case_id: str = ""
    last_updated_timestamp: str = ""


class AmbulanceAssignmentModel(BaseModel):
    case_id: str
    ambulance_id: str
    eta_to_patient: int = 0
    status: Literal["dispatched", "arrived", "transporting"] = "dispatched"
    assigned_timestamp: str = ""


class RouteMetricsModel(BaseModel):
    distance_km: float = 0.0
    estimated_travel_time: int = 0
    traffic_level: Literal["low", "medium", "high"] = "low"


class RouteModel(BaseModel):
    case_id: str
    source: CoordinatesModel = Field(default_factory=CoordinatesModel)
    destination_hospital_id: str
    route_metrics: RouteMetricsModel = Field(default_factory=RouteMetricsModel)
    route_polyline: str = ""
    timestamp: str = ""
