from typing import Dict

from logic.models.patient_model import PatientEmergencyModel
from logic.utils.claude_client import interpret_triage_context


def run_triage_agent(patient: PatientEmergencyModel) -> Dict:
    return interpret_triage_context(
        symptoms=patient.symptoms,
        condition_flags=patient.condition_flags.model_dump(),
    )
