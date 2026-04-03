import logging
from typing import Dict

from logic.agents.decision_router import route_decision
from logic.agents.explanation_agent import run_explanation_agent
from logic.agents.input_agent import run_input_agent
from logic.agents.triage_agent import run_triage_agent
from logic.models.patient_model import CoordinatesModel, PatientEmergencyModel, VitalsModel
from logic.services.ambulance_service import assign_ambulance
from logic.services.hospital_service import recommend_hospitals
from logic.services.triage_service import evaluate_triage
from logic.utils.db_store import persist_core_outputs, persist_new_case

logger = logging.getLogger(__name__)

_DEFAULT_LOCATION = CoordinatesModel(latitude=18.518, longitude=73.815)


def run_public_pipeline(input_text: str, blockchain_history=None, latitude=None, longitude=None, vitals: dict = None) -> Dict:
    patient_data = run_input_agent(input_text)
    patient = PatientEmergencyModel(**patient_data)

    if latitude is not None and longitude is not None:
        patient.location = CoordinatesModel(latitude=float(latitude), longitude=float(longitude))
    elif not (17.0 <= patient.location.latitude <= 20.0 and 72.5 <= patient.location.longitude <= 75.5):
        patient.location = _DEFAULT_LOCATION

    if vitals:
        patient.vitals = VitalsModel(
            heart_rate=int(vitals.get("heart_rate") or patient.vitals.heart_rate),
            systolic_bp=int(vitals.get("systolic_bp") or patient.vitals.systolic_bp),
            diastolic_bp=int(vitals.get("diastolic_bp") or patient.vitals.diastolic_bp),
            spo2=float(vitals.get("spo2") or patient.vitals.spo2),
            respiratory_rate=int(vitals.get("respiratory_rate") or patient.vitals.respiratory_rate),
            temperature=float(vitals.get("temperature") or patient.vitals.temperature),
        )

    try:
        persist_new_case(patient)
    except Exception as exc:
        logger.error(f"[PIPELINE] persist_new_case failed for {patient.case_id}: {exc}")

    triage_context = run_triage_agent(patient, blockchain_history=blockchain_history)
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
        "patient_id": patient.patient_id,
        "triage": {
            "severity": severity,
            "urgency": urgency.upper(),
            "time_to_critical_minutes": patient.triage_output.estimated_time_to_critical,
            "needs_ICU": patient.triage_output.needs_ICU,
            "needs_ventilator": patient.triage_output.needs_ventilator,
            "specialist": patient.triage_output.required_specialist,
        },
        "diagnosis": {
            "probable": triage_context.get("diagnosis"),
            "reasoning": triage_context.get("diagnosis_reasoning"),
        } if triage_context.get("diagnosis") else None,
        "decision_type": decision.decision_type,
        "routing": None,
        "alternatives": [],
        "ambulance": None,
        "advice": None,
        "risk_flags": [],
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
        if recs.recommendations:
            top = recs.recommendations[0]
            base_response["routing"] = {
                "hospital_id": top.hospital_id,
                "name": top.hospital_name,
                "latitude": top.latitude,
                "longitude": top.longitude,
                "eta": top.eta,
                "distance_km": top.distance_km,
                "compatibility": top.compatibility.upper(),
                "score": top.score,
                "load_percentage": top.hospital_state.load_percentage,
                "intake_delay": top.hospital_state.intake_delay,
                "pros": top.pros,
                "cons": top.cons,
                "explanation": top.explanation,
            }
            base_response["alternatives"] = [
                {
                    "hospital_id": h.hospital_id, "name": h.hospital_name,
                    "latitude": h.latitude, "longitude": h.longitude,
                    "eta": h.eta, "distance_km": h.distance_km,
                    "compatibility": h.compatibility.upper(),
                    "score": h.score,
                    "load_percentage": h.hospital_state.load_percentage,
                    "intake_delay": h.hospital_state.intake_delay,
                    "explanation": h.explanation,
                }
                for h in recs.recommendations[1:]
            ]
            base_response["risk_flags"] = top.risk_flags
        base_response["events"].append("ADVICE_ISSUED")

        try:
            from logic.utils.claude_client import generate_first_aid_steps
            base_response["first_aid"] = generate_first_aid_steps(
                diagnosis=triage_context.get("diagnosis", "Unknown emergency"),
                urgency=urgency,
                condition_flags={
                    "conscious": patient.condition_flags.conscious,
                    "breathing": patient.condition_flags.breathing,
                    "bleeding": patient.condition_flags.bleeding,
                },
                specialist=triage_eval["requirements"].get("specialist", "general"),
                advice_action=(base_response.get("advice") or {}).get("message", ""),
            )
        except Exception as exc:
            logger.warning(f"[PIPELINE] first_aid generation skipped: {exc}")
            base_response["first_aid"] = []

        try:
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
        except Exception as exc:
            logger.error(f"[PIPELINE] persist_core_outputs failed for {patient.case_id}: {exc}")
        return base_response

    recommendations = recommend_hospitals(
        case_id=patient.case_id,
        patient_location=patient.location,
        requirements=triage_eval["requirements"],
        top_n=3,
    )
    recommendations.recommendations = run_explanation_agent(recommendations.recommendations)

    if recommendations.recommendations:
        top = recommendations.recommendations[0]
        base_response["routing"] = {
            "hospital_id": top.hospital_id,
            "name": top.hospital_name,
            "latitude": top.latitude,
            "longitude": top.longitude,
            "eta": top.eta,
            "distance_km": top.distance_km,
            "compatibility": top.compatibility.upper(),
            "score": top.score,
            "load_percentage": top.hospital_state.load_percentage,
            "intake_delay": top.hospital_state.intake_delay,
            "pros": top.pros,
            "cons": top.cons,
            "explanation": top.explanation,
        }
        base_response["alternatives"] = [
            {
                "hospital_id": h.hospital_id, "name": h.hospital_name,
                "latitude": h.latitude, "longitude": h.longitude,
                "eta": h.eta, "distance_km": h.distance_km,
                "compatibility": h.compatibility.upper(),
                "score": h.score,
                "load_percentage": h.hospital_state.load_percentage,
                "intake_delay": h.hospital_state.intake_delay,
                "explanation": h.explanation,
            }
            for h in recommendations.recommendations[1:]
        ]
        base_response["risk_flags"] = top.risk_flags
    base_response["events"].append("RECOMMENDATION_GENERATED")

    ambulance = None
    if decision.decision_type == "emergency_routing":
        ambulance = assign_ambulance(case_id=patient.case_id, patient_location=patient.location)
        base_response["ambulance"] = {
            "id": ambulance.ambulance_id,
            "eta_to_patient": ambulance.eta_to_patient,
            "status": ambulance.status,
        } if ambulance else None
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

    try:
        from logic.utils.claude_client import generate_first_aid_steps
        _adv = base_response.get("advice") or {}
        base_response["first_aid"] = generate_first_aid_steps(
            diagnosis=triage_context.get("diagnosis", "Unknown emergency"),
            urgency=urgency,
            condition_flags={
                "conscious": patient.condition_flags.conscious,
                "breathing": patient.condition_flags.breathing,
                "bleeding": patient.condition_flags.bleeding,
            },
            specialist=triage_eval["requirements"].get("specialist", "general"),
            advice_action=_adv.get("action", _adv.get("message", "")),
        )
    except Exception as exc:
        logger.warning(f"[PIPELINE] first_aid generation skipped: {exc}")
        base_response["first_aid"] = []

    try:
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
    except Exception as exc:
        logger.error(f"[PIPELINE] persist_core_outputs failed for {patient.case_id}: {exc}")

    return base_response
