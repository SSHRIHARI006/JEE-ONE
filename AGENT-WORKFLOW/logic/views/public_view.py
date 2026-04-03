from typing import Dict

from logic.pipelines.public_pipeline import run_public_pipeline


def handle_public_request(input_text: str) -> Dict:
    return run_public_pipeline(input_text)
