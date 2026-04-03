from typing import Any, Dict

from logic.models.patient_model import PatientEmergencyModel


def _to_bool(value: Any, default: bool) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        lowered = value.strip().lower()
        if lowered in {"true", "yes", "1"}:
            return True
        if lowered in {"false", "no", "0"}:
            return False
    return default


def _to_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _to_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def validate_patient_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    safe_payload = dict(payload or {})
    safe_payload["case_id"] = str(safe_payload.get("case_id") or "")
    safe_payload["patient_id"] = str(safe_payload.get("patient_id") or "unknown")
    safe_payload["source_type"] = (
        safe_payload.get("source_type") if safe_payload.get("source_type") in {"public", "ambulance"} else "public"
    )
    safe_payload["timestamp"] = str(safe_payload.get("timestamp") or "")

    demographics = safe_payload.get("demographics") or {}
    safe_payload["demographics"] = {
        "age": _to_int(demographics.get("age")),
        "gender": str(demographics.get("gender") or "unknown"),
        "weight": _to_float(demographics.get("weight")),
    }

    location = safe_payload.get("location") or {}
    safe_payload["location"] = {
        "latitude": _to_float(location.get("latitude")),
        "longitude": _to_float(location.get("longitude")),
    }

    vitals = safe_payload.get("vitals") or {}
    safe_payload["vitals"] = {
        "heart_rate": _to_int(vitals.get("heart_rate")),
        "systolic_bp": _to_int(vitals.get("systolic_bp")),
        "diastolic_bp": _to_int(vitals.get("diastolic_bp")),
        "spo2": _to_float(vitals.get("spo2")),
        "respiratory_rate": _to_int(vitals.get("respiratory_rate")),
        "temperature": _to_float(vitals.get("temperature")),
    }

    flags = safe_payload.get("condition_flags") or {}
    safe_payload["condition_flags"] = {
        "conscious": _to_bool(flags.get("conscious"), True),
        "breathing": _to_bool(flags.get("breathing"), True),
        "bleeding": _to_bool(flags.get("bleeding"), False),
    }

    safe_payload["symptoms"] = [str(x) for x in (safe_payload.get("symptoms") or [])]
    safe_payload["injury_type"] = str(safe_payload.get("injury_type") or "unknown")
    safe_payload["pain_level"] = _to_int(safe_payload.get("pain_level"))
    safe_payload["time_since_incident"] = _to_int(safe_payload.get("time_since_incident"))

    medical_context = safe_payload.get("medical_context") or {}
    safe_payload["medical_context"] = {
        "history": [str(x) for x in (medical_context.get("history") or [])],
        "allergies": [str(x) for x in (medical_context.get("allergies") or [])],
    }

    triage_output = safe_payload.get("triage_output") or {}
    urgency = triage_output.get("urgency_level")
    safe_payload["triage_output"] = {
        "severity_score": _to_int(triage_output.get("severity_score")),
        "urgency_level": urgency if urgency in {"low", "medium", "high", "critical"} else "low",
        "needs_ICU": _to_bool(triage_output.get("needs_ICU"), False),
        "needs_ventilator": _to_bool(triage_output.get("needs_ventilator"), False),
        "needs_surgery": _to_bool(triage_output.get("needs_surgery"), False),
        "required_specialist": str(triage_output.get("required_specialist") or "general"),
        "estimated_time_to_critical": _to_int(triage_output.get("estimated_time_to_critical")),
    }

    validated = PatientEmergencyModel(**safe_payload)
    return validated.model_dump()
