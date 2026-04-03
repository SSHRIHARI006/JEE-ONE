from logic.models.patient_model import AgentDecisionModel


def route_decision(case_id: str, severity_score: int) -> AgentDecisionModel:
    if severity_score <= 3:
        return AgentDecisionModel(
            case_id=case_id,
            decision_type="advice",
            confidence_score=0.9,
            reasoning_summary="Low severity based on deterministic triage score.",
        )
    if 4 <= severity_score <= 6:
        return AgentDecisionModel(
            case_id=case_id,
            decision_type="hospital_suggestion",
            confidence_score=0.92,
            reasoning_summary="Moderate severity requires hospital recommendation.",
        )
    return AgentDecisionModel(
        case_id=case_id,
        decision_type="emergency_routing",
        confidence_score=0.95,
        reasoning_summary="High severity requires emergency routing.",
    )
