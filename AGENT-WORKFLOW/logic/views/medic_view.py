from typing import Dict

from logic.pipelines.medic_pipeline import run_medic_pipeline


def handle_medic_request(input_text: str) -> Dict:
    return run_medic_pipeline(input_text)
