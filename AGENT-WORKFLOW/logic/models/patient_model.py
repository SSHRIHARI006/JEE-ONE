from typing import Any, Dict, List, Literal, Optional

from pydantic import BaseModel, Field


class DemographicsModel(BaseModel):
    age: int = 0
    gender: str = "unknown"
    weight: float = 0.0


class CoordinatesModel(BaseModel):
    latitude: float = 0.0
    longitude: float = 0.0


class VitalsModel(BaseModel):
    heart_rate: int = 0
    systolic_bp: int = 0
    diastolic_bp: int = 0
    spo2: float = 0.0
    respiratory_rate: int = 0
    temperature: float = 0.0


class ConditionFlagsModel(BaseModel):
    conscious: bool = True
    breathing: bool = True
    bleeding: bool = False


class MedicalContextModel(BaseModel):
    history: List[str] = Field(default_factory=list)
    allergies: List[str] = Field(default_factory=list)


class TriageOutputModel(BaseModel):
    severity_score: int = 0
    urgency_level: Literal["low", "medium", "high", "critical"] = "low"
    needs_ICU: bool = False
    needs_ventilator: bool = False
    needs_surgery: bool = False
    required_specialist: str = "general"
    estimated_time_to_critical: int = 0


class PatientEmergencyModel(BaseModel):
    case_id: str
    patient_id: str = "unknown"
    source_type: Literal["public", "ambulance"] = "public"
    timestamp: str
    demographics: DemographicsModel = Field(default_factory=DemographicsModel)
    location: CoordinatesModel = Field(default_factory=CoordinatesModel)
    vitals: VitalsModel = Field(default_factory=VitalsModel)
    condition_flags: ConditionFlagsModel = Field(default_factory=ConditionFlagsModel)
    symptoms: List[str] = Field(default_factory=list)
    injury_type: str = "unknown"
    pain_level: int = 0
    time_since_incident: int = 0
    medical_context: MedicalContextModel = Field(default_factory=MedicalContextModel)
    triage_output: TriageOutputModel = Field(default_factory=TriageOutputModel)


class AgentDecisionModel(BaseModel):
    case_id: str
    decision_type: Literal["advice", "hospital_suggestion", "emergency_routing"]
    confidence_score: float
    reasoning_summary: str


class EHRModel(BaseModel):
    patient_id: str
    past_conditions: List[str] = Field(default_factory=list)
    medications: List[str] = Field(default_factory=list)
    allergies: List[str] = Field(default_factory=list)
    surgeries: List[str] = Field(default_factory=list)
    risk_score: float = 0.0
    last_updated: str = ""


class EventLogModel(BaseModel):
    event_id: str
    case_id: str
    event_type: Literal[
        "triage",
        "recommendation",
        "ambulance_assigned",
        "hospital_notified",
        "route_updated",
        "case_closed",
    ]
    metadata: Dict[str, Any] = Field(default_factory=dict)
    timestamp: str
