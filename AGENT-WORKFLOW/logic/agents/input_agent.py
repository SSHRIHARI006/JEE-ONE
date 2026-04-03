from typing import Dict

from logic.utils.claude_client import extract_structured_data
from logic.utils.validators import validate_patient_payload


def run_input_agent(input_text: str) -> Dict:
    first_try = extract_structured_data(input_text)
    try:
        return validate_patient_payload(first_try)
    except Exception:
        second_try = extract_structured_data(input_text)
        try:
            return validate_patient_payload(second_try)
        except Exception:
            return validate_patient_payload({
                "case_id": "case-fallback",
                "timestamp": "",
                "source_type": "public",
            })
