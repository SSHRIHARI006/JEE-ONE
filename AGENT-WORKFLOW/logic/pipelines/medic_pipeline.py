from datetime import datetime, timezone
from typing import Dict

from logic.agents.explanation_agent import run_explanation_agent
from logic.agents.input_agent import run_input_agent
from logic.agents.triage_agent import run_triage_agent
from logic.models.hospital_model import (
    HospitalNotificationModel,
    HospitalNotificationRequiredResourcesModel,
)
from logic.models.patient_model import CoordinatesModel, PatientEmergencyModel, VitalsModel

_DEFAULT_LOCATION = CoordinatesModel(latitude=18.518, longitude=73.815)
from logic.services.hospital_service import recommend_hospitals
from logic.services.routing_service import build_route
from logic.services.triage_service import evaluate_triage
from logic.utils.db_store import (
    load_hospital_coordinates,
    persist_core_outputs,
    persist_new_case,
)


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def run_medic_pipeline(input_text: str, blockchain_history=None, latitude=None, longitude=None, vitals: dict = None) -> Dict:
    patient_data = run_input_agent(input_text)
    patient = PatientEmergencyModel(**patient_data)
    patient.source_type = "ambulance"

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

    persist_new_case(patient)

    triage_context = run_triage_agent(patient, blockchain_history=blockchain_history)
    triage_eval = evaluate_triage(patient, triage_context)
    patient.triage_output = triage_eval["triage_output"]

    recommendations = recommend_hospitals(
        case_id=patient.case_id,
        patient_location=patient.location,
        requirements=triage_eval["requirements"],
        top_n=3,
    )
    recommendations.recommendations = run_explanation_agent(recommendations.recommendations)

    selected_hospital = recommendations.recommendations[0] if recommendations.recommendations else None
    alternatives = recommendations.recommendations[1:] if len(recommendations.recommendations) > 1 else []

    route = None
    notification = None
    selected_hospital_payload = None

    if selected_hospital is not None:
        hospital_coords = load_hospital_coordinates(selected_hospital.hospital_id)
        destination = (
            CoordinatesModel(
                latitude=float(hospital_coords["latitude"]),
                longitude=float(hospital_coords["longitude"]),
            )
            if hospital_coords is not None
            else patient.location
        )

        route = build_route(
            case_id=patient.case_id,
            source=patient.location,
            destination_hospital_id=selected_hospital.hospital_id,
            destination=destination,
        )

        notification = HospitalNotificationModel(
            case_id=patient.case_id,
            hospital_id=selected_hospital.hospital_id,
            patient_summary=", ".join(patient.symptoms) or "no_symptoms_provided",
            eta=selected_hospital.eta,
            severity_score=triage_eval["severity_score"],
            required_resources=HospitalNotificationRequiredResourcesModel(
                ICU=triage_eval["requirements"]["ICU"],
                ventilator=triage_eval["requirements"]["ventilator"],
                specialist=triage_eval["requirements"]["specialist"],
            ),
            status="sent",
            notified_at=_now_iso(),
        )

        selected_hospital_payload = {
            "id": selected_hospital.hospital_id,
            "name": selected_hospital.hospital_name,
            "reason": (
                f"Best combined score {selected_hospital.score} with compatibility "
                f"{selected_hospital.compatibility} and ETA {selected_hospital.eta} minutes"
            ),
            "compatibility": selected_hospital.compatibility,
            "risk_flags": selected_hospital.risk_flags,
            "rank": selected_hospital.rank,
            "score_label": selected_hospital.score_label,
        }

        selected_hospital_payload["rejected_reasons"] = [
            {
                "hospital_id": alt.hospital_id,
                "reason": (
                    f"Not chosen due to lower priority than selected option with score {alt.score}, "
                    f"compatibility {alt.compatibility}, and risk flags {', '.join(alt.risk_flags)}"
                ),
            }
            for alt in alternatives
        ]

    persist_core_outputs(
        case_id=patient.case_id,
        severity=triage_eval["severity_score"],
        urgency=patient.triage_output.urgency_level,
        needs_icu=triage_eval["requirements"]["ICU"],
        specialist=triage_eval["requirements"]["specialist"],
        recommendations=recommendations,
        ambulance_assignment=None,
        events=[
            "CASE_CREATED",
            "TRIAGED",
            "RECOMMENDATION_GENERATED",
            "HOSPITAL_SELECTED" if selected_hospital else "NO_HOSPITAL_SELECTED",
            "HOSPITAL_NOTIFIED" if notification else "NOTIFICATION_SKIPPED",
        ],
    )

    severity = triage_eval["severity_score"]
    urgency = patient.triage_output.urgency_level

    # Build routing + alternatives in the same shape as public_pipeline so
    # the Flutter app (and dashboard) can consume both pipelines identically.
    routing_payload = None
    if selected_hospital is not None:
        routing_payload = {
            "hospital_id": selected_hospital.hospital_id,
            "name": selected_hospital.hospital_name,
            "latitude": selected_hospital.latitude,
            "longitude": selected_hospital.longitude,
            "eta": selected_hospital.eta,
            "distance_km": selected_hospital.distance_km,
            "compatibility": selected_hospital.compatibility.upper(),
            "score": selected_hospital.score,
            "load_percentage": selected_hospital.hospital_state.load_percentage,
            "intake_delay": selected_hospital.hospital_state.intake_delay,
            "pros": selected_hospital.pros,
            "cons": selected_hospital.cons,
            "explanation": selected_hospital.explanation,
        }

    alts_payload = [
        {
            "hospital_id": alt.hospital_id,
            "name": alt.hospital_name,
            "latitude": alt.latitude,
            "longitude": alt.longitude,
            "eta": alt.eta,
            "distance_km": alt.distance_km,
            "compatibility": alt.compatibility.upper(),
            "score": alt.score,
            "load_percentage": alt.hospital_state.load_percentage,
            "intake_delay": alt.hospital_state.intake_delay,
            "explanation": alt.explanation,
        }
        for alt in alternatives
    ]

    events = [
        "CASE_CREATED",
        "TRIAGED",
        "DECISION_MADE",
        "RECOMMENDATION_GENERATED",
        "HOSPITAL_SELECTED" if selected_hospital else "NO_HOSPITAL_SELECTED",
        "HOSPITAL_NOTIFIED" if notification else "NOTIFICATION_SKIPPED",
        "IN_TRANSIT" if selected_hospital else "NOT_IN_TRANSIT",
        "ARRIVED" if selected_hospital else "NOT_ARRIVED",
    ]

    return {
        # ── Flutter-compatible keys (mirrors public_pipeline shape) ──────────
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
        "decision_type": "emergency_routing",
        "routing": routing_payload,
        "alternatives": alts_payload,
        "ambulance": None,
        "advice": {
            "message": f"CRITICAL EMERGENCY — {urgency.upper()} severity. Immediate medical attention required.",
            "action": "Do not move the patient unless directed. Keep airway clear. Emergency services dispatched.",
        },
        "risk_flags": selected_hospital.risk_flags if selected_hospital else [],
        "events": events,
        # ── Medic-specific fields (for hospital notification / route nav) ────
        "selected_hospital_id": selected_hospital.hospital_id if selected_hospital else None,
        "selected_hospital": selected_hospital_payload,
        "hospital_lock": bool(selected_hospital),
        "route": route.model_dump() if route else None,
        "hospital_notification": notification.model_dump() if notification else None,
    }
