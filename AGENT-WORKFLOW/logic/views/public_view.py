from typing import Dict, List, Optional

from logic.pipelines.public_pipeline import run_public_pipeline


def handle_public_request(input_text: str, blockchain_history: Optional[List[Dict]] = None, latitude=None, longitude=None, vitals: dict = None) -> Dict:
    return run_public_pipeline(input_text, blockchain_history=blockchain_history, latitude=latitude, longitude=longitude, vitals=vitals)
