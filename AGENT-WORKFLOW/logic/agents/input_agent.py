import uuid
from typing import Dict, Optional

from logic.utils.claude_client import extract_structured_data
from logic.utils.validators import validate_patient_payload


def run_input_agent(input_text: str, image_base64: Optional[str] = None) -> Dict:
    first_try = extract_structured_data(input_text)
    try:
        patient_payload = validate_patient_payload(first_try)
    except Exception:
        second_try = extract_structured_data(input_text)
        try:
            patient_payload = validate_patient_payload(second_try)
        except Exception:
            patient_payload = validate_patient_payload({
                "case_id": f"case-{uuid.uuid4().hex[:8]}",
                "timestamp": "",
                "source_type": "public",
            })

    # Scene context is additive — callers must pop it before constructing
    # PatientEmergencyModel since it is not a model field.
    if image_base64:
        try:
            from logic.utils.claude_client import extract_scene_context
            patient_payload["scene_context"] = extract_scene_context(image_base64)
        except Exception:
            patient_payload["scene_context"] = None
    else:
        patient_payload["scene_context"] = None

    return patient_payload
