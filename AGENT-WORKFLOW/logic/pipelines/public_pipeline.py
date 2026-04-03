from typing import Dict

from logic.agents.decision_router import route_decision
from logic.agents.explanation_agent import run_explanation_agent
from logic.agents.triage_agent import run_triage_agent
from logic.services.ambulance_service import assign_ambulance
from logic.services.hospital_service import recommend_hospitals
from logic.services.triage_service import evaluate_triage
from logic.utils.db_store import load_latest_patient_case, persist_core_outputs


def run_public_pipeline(input_text: str) -> Dict:
    patient = load_latest_patient_case()

    triage_context = run_triage_agent(patient)
    triage_eval = evaluate_triage(patient, triage_context)

    patient.triage_output = triage_eval["triage_output"]

    decision = route_decision(case_id=patient.case_id, severity_score=triage_eval["severity_score"])

    base_response = {
        "case_id": patient.case_id,
        "severity": triage_eval["severity_score"],
        "urgency_level": patient.triage_output.urgency_level,
        "time_to_critical": patient.triage_output.estimated_time_to_critical,
        "decision_type": decision.decision_type,
        "reasoning_summary": decision.reasoning_summary,
        "confidence_score": decision.confidence_score,
        "requirements": triage_eval["requirements"],
        "recommendations": [],
        "selected_recommendation": None,
        "alternatives": [],
        "ambulance": None,
        "advice": None,
        "events": ["CASE_CREATED", "TRIAGED", "DECISION_MADE"],
    }

    if decision.decision_type == "advice":
        base_response["advice"] = {
            "remedy": "Monitor symptoms and hydrate.",
            "precautions": "Seek help if breathing worsens or consciousness changes.",
        }
        base_response["events"].append("ADVICE_ISSUED")
        persist_core_outputs(
            case_id=patient.case_id,
            severity=triage_eval["severity_score"],
            urgency=patient.triage_output.urgency_level,
            needs_icu=triage_eval["requirements"]["ICU"],
            specialist=triage_eval["requirements"]["specialist"],
            recommendations=recommend_hospitals(
                case_id=patient.case_id,
                patient_location=patient.location,
                requirements=triage_eval["requirements"],
                top_n=1,
            ),
            ambulance_assignment=None,
            events=base_response["events"],
        )
        return base_response

    recommendations = recommend_hospitals(
        case_id=patient.case_id,
        patient_location=patient.location,
        requirements=triage_eval["requirements"],
        top_n=3,
    )
    recommendations.recommendations = run_explanation_agent(recommendations.recommendations)

    base_response["recommendations"] = [item.model_dump() for item in recommendations.recommendations]
    if recommendations.recommendations:
        base_response["selected_recommendation"] = recommendations.recommendations[0].model_dump()
        base_response["alternatives"] = [item.model_dump() for item in recommendations.recommendations[1:]]
    base_response["events"].append("RECOMMENDATION_GENERATED")

    ambulance = None
    if decision.decision_type == "emergency_routing":
        ambulance = assign_ambulance(case_id=patient.case_id, patient_location=patient.location)
        base_response["ambulance"] = ambulance.model_dump() if ambulance else None
        base_response["advice"] = {
            "message": "Immediate medical attention required",
        }
        base_response["events"].append("AMBULANCE_ASSIGNED")
        base_response["events"].append("IN_TRANSIT")
        base_response["events"].append("ARRIVED")

    persist_core_outputs(
        case_id=patient.case_id,
        severity=triage_eval["severity_score"],
        urgency=patient.triage_output.urgency_level,
        needs_icu=triage_eval["requirements"]["ICU"],
        specialist=triage_eval["requirements"]["specialist"],
        recommendations=recommendations,
        ambulance_assignment=ambulance if decision.decision_type == "emergency_routing" else None,
        events=base_response["events"],
    )

    return base_response
