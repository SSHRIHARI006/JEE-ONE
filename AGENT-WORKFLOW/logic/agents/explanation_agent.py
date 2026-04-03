from typing import List

from logic.models.recommendation_model import HospitalRecommendationItemModel
from logic.utils.claude_client import generate_recommendation_text


def run_explanation_agent(
    recommendations: List[HospitalRecommendationItemModel],
) -> List[HospitalRecommendationItemModel]:
    enhanced: List[HospitalRecommendationItemModel] = []
    for item in recommendations:
        text_output = generate_recommendation_text(item.model_dump())
        updated = item.model_copy(
            update={
                "pros": text_output.get("pros", []),
                "cons": text_output.get("cons", []),
                "explanation": text_output.get("explanation", ""),
            }
        )
        enhanced.append(updated)
    return enhanced
