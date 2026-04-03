from typing import List, Literal

from pydantic import BaseModel, Field


class ResourceMatchModel(BaseModel):
    ICU: bool = False
    ventilator: bool = False
    specialist: bool = False


class HospitalStateModel(BaseModel):
    load_percentage: float = 0.0
    intake_delay: int = 0
    readiness_score: float = 0.0


class HospitalRecommendationItemModel(BaseModel):
    hospital_id: str
    hospital_name: str
    eta: int = 0
    distance_km: float = 0.0
    compatibility: Literal["full", "partial", "risky"] = "risky"
    score: float = 0.0
    resource_match: ResourceMatchModel = Field(default_factory=ResourceMatchModel)
    hospital_state: HospitalStateModel = Field(default_factory=HospitalStateModel)
    risk_flags: List[str] = Field(default_factory=list)
    rank: int = 0
    score_label: str = ""
    pros: List[str] = Field(default_factory=list)
    cons: List[str] = Field(default_factory=list)
    explanation: str = ""


class HospitalRecommendationModel(BaseModel):
    case_id: str
    generated_at: str
    recommendations: List[HospitalRecommendationItemModel] = Field(default_factory=list)
