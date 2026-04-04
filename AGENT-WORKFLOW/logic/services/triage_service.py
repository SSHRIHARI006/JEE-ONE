from typing import Any, Dict, Optional

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
    if patient.vitals.spo2 > 0 and patient.vitals.spo2 < 92:
        score += 2
    if patient.pain_level >= 7:
        score += 1
    score += min(len(triage_context.get("risk_flags", [])), 3)
    return min(score, 10)


def evaluate_triage(
    patient: PatientEmergencyModel,
    triage_context: Dict,
    scene_context: Optional[Dict[str, Any]] = None,
) -> Dict:
    deterministic_severity = _severity_from_patient(patient, triage_context)

    # If the diagnostic agent returned a severity, take the higher of the two.
    diagnosis_severity = triage_context.get("diagnosis_severity")
    severity = max(deterministic_severity, diagnosis_severity) if diagnosis_severity else deterministic_severity

    # Scene fusion — image hint raises severity, never lowers it.
    scene_influence_applied = False
    scene_severity_hint_used: Optional[int] = None
    if scene_context:
        hint = int(scene_context.get("severity_estimate", 0) or 0)
        if hint > severity:
            severity = hint
            scene_influence_applied = True
            scene_severity_hint_used = hint

    # Safety floor: neurologic red-flag constellation should not be triaged low.
    suspected_conditions = triage_context.get("suspected_conditions", [])
    risk_flags = triage_context.get("risk_flags", [])
    if "neurologic_event" in suspected_conditions and "possible_stroke" in risk_flags:
        severity = max(severity, 7)

    urgency = _urgency_from_score(severity)

    needs_icu = severity >= 7
    needs_ventilator = (not patient.condition_flags.breathing) or (patient.vitals.spo2 > 0 and patient.vitals.spo2 < 90)
    needs_surgery = patient.condition_flags.bleeding and severity >= 6

    # Diagnostic agent's specialist takes precedence over rule-based fallback.
    specialist = triage_context.get("required_specialist") or "general"
    if str(specialist).strip().lower() in {"none", "null", "n/a", "na", "unknown", ""}:
        specialist = "general"
    if specialist == "general":
        if "cardiac_event" in triage_context.get("suspected_conditions", []):
            specialist = "cardiology"
        elif "respiratory_distress" in triage_context.get("suspected_conditions", []):
            specialist = "pulmonology"
        elif needs_surgery:
            specialist = "surgery"

    # Scene risk enrichment — deterministic, scene can shift specialist/ICU
    # only when severity warrants it, preventing low-quality images from
    # inflating requirements on benign cases.
    if scene_context and severity >= 5:
        indicators = " ".join(
            scene_context.get("visible_injuries", [])
            + scene_context.get("scene_hazards", [])
            + scene_context.get("recommended_resources", [])
        ).lower()
        if any(t in indicators for t in ["trauma", "laceration", "crush", "penetrat", "stab", "gunshot", "fracture", "impaled"]):
            needs_surgery = True
            if specialist == "general":
                specialist = "surgery"
        if any(t in indicators for t in ["fire", "burn", "chemical", "smoke", "hazmat"]):
            needs_icu = True
            if specialist == "general":
                specialist = "burns"
        if any(t in indicators for t in ["unconscious", "unresponsive", "seizure", "coma"]):
            needs_icu = True

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
        "scene_influence_applied": scene_influence_applied,
        "scene_severity_hint_used": scene_severity_hint_used,
    }
