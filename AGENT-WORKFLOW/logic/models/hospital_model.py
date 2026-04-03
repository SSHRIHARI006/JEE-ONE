from typing import Dict, List, Literal

from pydantic import BaseModel, Field

from logic.models.patient_model import CoordinatesModel


class HospitalFacilitiesModel(BaseModel):
    has_ICU: bool = False
    has_ventilator: bool = False
    has_CT_scan: bool = False
    has_MRI: bool = False


class HospitalCapacityModel(BaseModel):
    max_ICU_beds: int = 0
    max_ventilators: int = 0
    max_general_beds: int = 0


class HospitalStaticModel(BaseModel):
    hospital_id: str
    hospital_name: str
    location: CoordinatesModel
    facilities: HospitalFacilitiesModel = Field(default_factory=HospitalFacilitiesModel)
    specialists_available: List[str] = Field(default_factory=list)
    capacity: HospitalCapacityModel = Field(default_factory=HospitalCapacityModel)
    hospital_type: str = "general"
    avg_treatment_time: int = 0


class HospitalAvailabilityModel(BaseModel):
    available_ICU_beds: int = 0
    available_ventilators: int = 0
    available_general_beds: int = 0


class HospitalDynamicModel(BaseModel):
    hospital_id: str
    availability: HospitalAvailabilityModel = Field(default_factory=HospitalAvailabilityModel)
    current_load_percentage: float = 0.0
    avg_intake_delay: int = 0
    status: Literal["open", "full", "emergency_only"] = "open"
    staff_availability_score: float = 0.0
    readiness_score: float = 0.0
    last_updated_timestamp: str = ""


class HospitalNotificationRequiredResourcesModel(BaseModel):
    ICU: bool = False
    ventilator: bool = False
    specialist: str = "general"


class HospitalNotificationModel(BaseModel):
    case_id: str
    hospital_id: str
    patient_summary: str
    eta: int = 0
    severity_score: int = 0
    required_resources: HospitalNotificationRequiredResourcesModel = (
        Field(default_factory=HospitalNotificationRequiredResourcesModel)
    )
    status: Literal["sent", "acknowledged", "preparing"] = "sent"
    notified_at: str = ""
