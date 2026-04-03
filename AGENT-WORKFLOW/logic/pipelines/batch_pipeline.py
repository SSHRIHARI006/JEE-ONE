from typing import Dict

from logic.services.batch_routing_service import assign_patients_batch


def run_batch_pipeline(batch_size: int = 5) -> Dict:
    return assign_patients_batch(batch_size=batch_size)