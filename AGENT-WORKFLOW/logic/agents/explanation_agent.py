from typing import List

from logic.models.recommendation_model import HospitalRecommendationItemModel
from logic.utils.claude_client import generate_batch_explanations


def run_explanation_agent(
    recommendations: List[HospitalRecommendationItemModel],
) -> List[HospitalRecommendationItemModel]:
    if not recommendations:
        return recommendations

    batch_output = generate_batch_explanations([item.model_dump() for item in recommendations])

    enhanced: List[HospitalRecommendationItemModel] = []
    for item, text_output in zip(recommendations, batch_output):
        updated = item.model_copy(
            update={
                "pros": text_output.get("pros", []),
                "cons": text_output.get("cons", []),
                "explanation": text_output.get("explanation", ""),
            }
        )
        enhanced.append(updated)
    return enhanced
