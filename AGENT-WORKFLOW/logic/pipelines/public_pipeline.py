from typing import Dict

from logic.agents.decision_router import route_decision
from logic.agents.explanation_agent import run_explanation_agent
from logic.agents.input_agent import run_input_agent
from logic.agents.triage_agent import run_triage_agent
from logic.models.patient_model import CoordinatesModel, PatientEmergencyModel
from logic.services.ambulance_service import assign_ambulance
from logic.services.hospital_service import recommend_hospitals
from logic.services.triage_service import evaluate_triage
from logic.utils.db_store import persist_core_outputs, persist_new_case

_DEFAULT_LOCATION = CoordinatesModel(latitude=18.518, longitude=73.815)


def run_public_pipeline(input_text: str) -> Dict:
    patient_data = run_input_agent(input_text)
    patient = PatientEmergencyModel(**patient_data)

    lat, lon = patient.location.latitude, patient.location.longitude
    if not (17.0 <= lat <= 20.0 and 72.5 <= lon <= 75.5):
        patient.location = _DEFAULT_LOCATION

    persist_new_case(patient)

    triage_context = run_triage_agent(patient)
    triage_eval = evaluate_triage(patient, triage_context)
    patient.triage_output = triage_eval["triage_output"]

    decision = route_decision(case_id=patient.case_id, severity_score=triage_eval["severity_score"])

    # Safety guard: severity >= 7 must never resolve to routine advice
    if triage_eval["severity_score"] >= 7 and decision.decision_type == "advice":
        from logic.models.patient_model import AgentDecisionModel
        decision = AgentDecisionModel(
            case_id=patient.case_id,
            decision_type="emergency_routing",
            confidence_score=0.99,
            reasoning_summary="Overridden: severity >= 7 requires emergency routing.",
        )

    severity = triage_eval["severity_score"]
    urgency = patient.triage_output.urgency_level

    base_response = {
        "case_id": patient.case_id,
        "case_summary": {
            "severity": severity,
            "urgency_level": urgency.upper(),
            "time_to_critical_minutes": patient.triage_output.estimated_time_to_critical,
            "needs_ICU": patient.triage_output.needs_ICU,
            "needs_ventilator": patient.triage_output.needs_ventilator,
            "required_specialist": patient.triage_output.required_specialist,
        },
        "decision_type": decision.decision_type,
        "reasoning_summary": decision.reasoning_summary,
        "confidence_score": decision.confidence_score,
        "requirements": triage_eval["requirements"],
        "recommendations": [],
        "selected_recommendation": None,
        "alternatives": [],
        "ambulance": None,
        "advice": None,
        "risk_summary": [],
        "events": ["CASE_CREATED", "TRIAGED", "DECISION_MADE"],
    }

    if decision.decision_type == "advice":
        recs = recommend_hospitals(
            case_id=patient.case_id,
            patient_location=patient.location,
            requirements=triage_eval["requirements"],
            top_n=1,
        )
        recs.recommendations = run_explanation_agent(recs.recommendations)

        base_response["advice"] = {
            "message": "Symptoms appear non-critical. Monitor and follow precautions.",
            "remedy": "Rest, hydrate, and monitor symptoms closely.",
            "precautions": "Seek emergency care if breathing worsens, consciousness changes, or pain escalates.",
        }
        base_response["recommendations"] = [item.model_dump() for item in recs.recommendations]
        if recs.recommendations:
            base_response["selected_recommendation"] = recs.recommendations[0].model_dump()
            base_response["risk_summary"] = recs.recommendations[0].risk_flags
        base_response["events"].append("ADVICE_ISSUED")

        persist_core_outputs(
            case_id=patient.case_id,
            severity=severity,
            urgency=urgency,
            needs_icu=triage_eval["requirements"]["ICU"],
            specialist=triage_eval["requirements"]["specialist"],
            recommendations=recs,
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
        base_response["risk_summary"] = recommendations.recommendations[0].risk_flags
    base_response["events"].append("RECOMMENDATION_GENERATED")

    ambulance = None
    if decision.decision_type == "emergency_routing":
        ambulance = assign_ambulance(case_id=patient.case_id, patient_location=patient.location)
        base_response["ambulance"] = ambulance.model_dump() if ambulance else None
        base_response["advice"] = {
            "message": f"CRITICAL EMERGENCY — {urgency.upper()} severity. Immediate medical attention required.",
            "action": "Do not move the patient unless directed. Keep airway clear. Emergency services dispatched.",
        }
        base_response["events"].extend(["AMBULANCE_ASSIGNED", "IN_TRANSIT", "ARRIVED"])
    elif decision.decision_type == "hospital_suggestion":
        base_response["advice"] = {
            "message": "Moderate severity. Proceed to recommended hospital promptly.",
            "action": "Transport patient to nearest recommended hospital. Monitor vitals en route.",
        }
        base_response["events"].append("HOSPITAL_SUGGESTED")

    persist_core_outputs(
        case_id=patient.case_id,
        severity=severity,
        urgency=urgency,
        needs_icu=triage_eval["requirements"]["ICU"],
        specialist=triage_eval["requirements"]["specialist"],
        recommendations=recommendations,
        ambulance_assignment=ambulance if decision.decision_type == "emergency_routing" else None,
        events=base_response["events"],
    )

    return base_response
