from typing import Dict

from logic.models.patient_model import PatientEmergencyModel, TriageOutputModel


def _urgency_from_score(score: int) -> str:
    if score <= 3:
        return "low"
    if score <= 6:
        return "medium"
    if score <= 8:
        return "high"
    return "critical"


def _severity_from_patient(patient: PatientEmergencyModel, triage_context: Dict) -> int:
    score = 1
    if not patient.condition_flags.conscious:
        score += 3
    if not patient.condition_flags.breathing:
        score += 4
    if patient.condition_flags.bleeding:
        score += 2
    if patient.vitals.spo2 and patient.vitals.spo2 < 92:
        score += 2
    if patient.pain_level >= 7:
        score += 1
    score += min(len(triage_context.get("risk_flags", [])), 3)
    return min(score, 10)


def evaluate_triage(patient: PatientEmergencyModel, triage_context: Dict) -> Dict:
    severity = _severity_from_patient(patient, triage_context)
    urgency = _urgency_from_score(severity)

    needs_icu = severity >= 7
    needs_ventilator = (not patient.condition_flags.breathing) or patient.vitals.spo2 < 90
    needs_surgery = patient.condition_flags.bleeding and severity >= 6

    specialist = "general"
    if "cardiac_event" in triage_context.get("suspected_conditions", []):
        specialist = "cardiology"
    elif "respiratory_distress" in triage_context.get("suspected_conditions", []):
        specialist = "pulmonology"
    elif needs_surgery:
        specialist = "surgery"

    triage_output = TriageOutputModel(
        severity_score=severity,
        urgency_level=urgency,
        needs_ICU=needs_icu,
        needs_ventilator=needs_ventilator,
        needs_surgery=needs_surgery,
        required_specialist=specialist,
        estimated_time_to_critical=15 if severity >= 8 else 45 if severity >= 6 else 180,
    )

    return {
        "severity_score": severity,
        "requirements": {
            "ICU": needs_icu,
            "ventilator": needs_ventilator,
            "specialist": specialist,
        },
        "triage_output": triage_output,
    }
