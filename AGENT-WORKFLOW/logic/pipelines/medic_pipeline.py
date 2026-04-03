from datetime import datetime, timezone
from typing import Dict

from logic.agents.explanation_agent import run_explanation_agent
from logic.agents.triage_agent import run_triage_agent
from logic.models.hospital_model import (
    HospitalNotificationModel,
    HospitalNotificationRequiredResourcesModel,
)
from logic.models.patient_model import CoordinatesModel
from logic.services.hospital_service import recommend_hospitals
from logic.services.routing_service import build_route
from logic.services.triage_service import evaluate_triage
from logic.utils.db_store import (
    load_hospital_coordinates,
    load_latest_patient_case,
    persist_core_outputs,
)


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def run_medic_pipeline(input_text: str) -> Dict:
    patient = load_latest_patient_case()
    patient.source_type = "ambulance"

    triage_context = run_triage_agent(patient)
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

    return {
        "case_id": patient.case_id,
        "severity": triage_eval["severity_score"],
        "urgency_level": patient.triage_output.urgency_level,
        "time_to_critical": patient.triage_output.estimated_time_to_critical,
        "requirements": triage_eval["requirements"],
        "hospital_recommendations": [item.model_dump() for item in recommendations.recommendations],
        "alternatives": [item.model_dump() for item in alternatives],
        "selected_hospital_id": selected_hospital.hospital_id if selected_hospital else None,
        "selected_hospital": selected_hospital_payload,
        "hospital_lock": bool(selected_hospital),
        "route": route.model_dump() if route else None,
        "hospital_notification": notification.model_dump() if notification else None,
        "events": [
            "CASE_CREATED",
            "TRIAGED",
            "RECOMMENDATION_GENERATED",
            "HOSPITAL_SELECTED" if selected_hospital else "NO_HOSPITAL_SELECTED",
            "HOSPITAL_NOTIFIED" if notification else "NOTIFICATION_SKIPPED",
            "IN_TRANSIT" if selected_hospital else "NOT_IN_TRANSIT",
            "ARRIVED" if selected_hospital else "NOT_ARRIVED",
        ],
    }
