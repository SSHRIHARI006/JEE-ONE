from typing import Dict, List, Optional

from logic.models.patient_model import PatientEmergencyModel
from logic.utils.claude_client import (
    interpret_triage_context,
    run_blockchain_diagnostic_agent,
    run_diagnostic_agent,
)


def run_triage_agent(
    patient: PatientEmergencyModel,
    blockchain_history: Optional[List[Dict]] = None,
) -> Dict:
    context = interpret_triage_context(
        symptoms=patient.symptoms,
        condition_flags=patient.condition_flags.model_dump(),
    )

    if blockchain_history:
        diagnosis = run_blockchain_diagnostic_agent(
            symptoms=patient.symptoms,
            vitals=patient.vitals.model_dump(),
            blockchain_history=blockchain_history,
        )
    else:
        diagnosis = run_diagnostic_agent(
            symptoms=patient.symptoms,
            condition_flags=patient.condition_flags.model_dump(),
            vitals=patient.vitals.model_dump(),
            medical_history=patient.medical_context.model_dump(),
        )

    # If Claude returned nothing, produce a heuristic diagnosis from what we know
    if not diagnosis:
        diagnosis = _heuristic_diagnosis(patient, context)

    context.update(diagnosis)
    return context


def _heuristic_diagnosis(patient: PatientEmergencyModel, context: Dict) -> Dict:
    conditions = context.get("suspected_conditions", [])
    flags = context.get("risk_flags", [])

    if "cardiac_event" in conditions and "unconscious" in flags:
        label = "Cardiac Arrest"
        reasoning = "Chest pain with loss of consciousness indicates possible cardiac arrest."
        severity = 9
        specialist = "cardiology"
    elif "cardiac_event" in conditions:
        label = "Acute Coronary Syndrome"
        reasoning = "Chest pain symptoms consistent with ACS. Cardiac evaluation required."
        severity = 6
        specialist = "cardiology"
    elif "respiratory_distress" in conditions and "airway_compromise" in flags:
        label = "Acute Respiratory Failure"
        reasoning = "Breathing issue with airway compromise indicates respiratory failure."
        severity = 8
        specialist = "pulmonology"
    elif "respiratory_distress" in conditions:
        label = "Respiratory Distress"
        reasoning = "Breathing difficulty requires immediate pulmonary assessment."
        severity = 5
        specialist = "pulmonology"
    elif "unconscious" in flags:
        label = "Altered Consciousness — Unknown Cause"
        reasoning = "Unconsciousness with no known history. Neurological and trauma causes must be excluded."
        severity = 7
        specialist = "neurology"
    elif "active_bleeding" in flags:
        label = "Active Hemorrhage"
        reasoning = "Active bleeding present. Surgical evaluation required."
        severity = 6
        specialist = "surgery"
    elif patient.symptoms:
        label = f"Undifferentiated Emergency — {', '.join(patient.symptoms[:2])}"
        reasoning = "Symptoms present but insufficient data for a specific diagnosis. Full workup required."
        severity = 3
        specialist = "general"
    else:
        return {}

    return {
        "diagnosis": label,
        "diagnosis_reasoning": reasoning,
        "diagnosis_severity": severity,
        "required_specialist": specialist,
    }
