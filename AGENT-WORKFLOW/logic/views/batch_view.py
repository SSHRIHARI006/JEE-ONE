from typing import Dict

from logic.pipelines.batch_pipeline import run_batch_pipeline


def handle_batch_request(batch_size: int = 5) -> Dict:
    return run_batch_pipeline(batch_size=batch_size)