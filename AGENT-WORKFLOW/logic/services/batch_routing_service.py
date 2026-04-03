from datetime import datetime, timezone
from typing import Dict, List, Optional

from logic.agents.explanation_agent import run_explanation_agent
from logic.models.ambulance_model import AmbulanceAssignmentModel
from logic.models.patient_model import PatientEmergencyModel
from logic.models.recommendation_model import HospitalRecommendationItemModel, HospitalRecommendationModel
from logic.services.ambulance_service import assign_ambulance
from logic.services.hospital_service import recommend_hospitals
from logic.services.triage_service import evaluate_triage
from logic.utils.db_store import load_critical_batch_patients, persist_batch_result


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _batch_penalty(
    candidate: HospitalRecommendationItemModel,
    assigned_count: int,
    total_patients: int,
) -> float:
    w_load = 10.0
    w_capacity = 12.0
    w_saturation = 14.0

    overload_penalty = (candidate.hospital_state.load_percentage / 100.0) * w_load

    remaining_icu = candidate.hospital_state.available_icu_beds
    capacity_penalty = 0.0
    if remaining_icu <= 0:
        capacity_penalty += 30.0
    elif remaining_icu == 1:
        capacity_penalty += 18.0
    elif remaining_icu == 2:
        capacity_penalty += 8.0

    if candidate.hospital_state.intake_delay >= 15:
        capacity_penalty += 8.0
    elif candidate.hospital_state.intake_delay >= 10:
        capacity_penalty += 4.0

    if candidate.compatibility == "partial":
        capacity_penalty += 7.0
    elif candidate.compatibility == "risky":
        capacity_penalty += 14.0

    future_penalty = 0.0
    if remaining_icu <= 1:
        future_penalty += 20.0
    elif remaining_icu == 2:
        future_penalty += 8.0

    saturation_penalty = (assigned_count / max(total_patients, 1)) * w_saturation
    if assigned_count >= max(1, total_patients // 3):
        saturation_penalty += 6.0

    return overload_penalty + capacity_penalty + future_penalty + saturation_penalty


def _choose_best_candidate(
    candidates: List[HospitalRecommendationItemModel],
    assigned_counts: Dict[str, int],
    total_patients: int,
) -> HospitalRecommendationItemModel:
    ranked_candidates: List[tuple[float, HospitalRecommendationItemModel]] = []
    for candidate in candidates:
        adjusted = candidate.score + _batch_penalty(
            candidate=candidate,
            assigned_count=assigned_counts.get(candidate.hospital_id, 0),
            total_patients=total_patients,
        )
        ranked_candidates.append((adjusted, candidate))

    ranked_candidates.sort(key=lambda item: (item[0], item[1].eta, -item[1].hospital_state.readiness_score))

    for _, candidate in ranked_candidates:
        if candidate.compatibility == "full" and candidate.hospital_state.available_icu_beds > 0:
            return candidate

    for _, candidate in ranked_candidates:
        if candidate.compatibility == "partial" and candidate.hospital_state.available_icu_beds >= 0:
            return candidate

    return ranked_candidates[0][1]


def assign_patients_batch(batch_size: int = 5) -> Dict:
    patients = load_critical_batch_patients(limit=batch_size)
    patients.sort(key=lambda patient: (-patient.triage_output.severity_score, patient.triage_output.estimated_time_to_critical))

    assignments: List[Dict] = []
    assigned_counts: Dict[str, int] = {}
    used_hospitals: Dict[str, int] = {}
    fallback_count = 0

    for patient in patients:
        triage_result = evaluate_triage(patient, {
            "suspected_conditions": ["cardiac_event"] if "chest_pain" in patient.symptoms else ["respiratory_distress"] if "breathing_issue" in patient.symptoms else [],
            "risk_flags": ["unconscious"] if not patient.condition_flags.conscious else [],
        })

        recommendations = recommend_hospitals(
            case_id=patient.case_id,
            patient_location=patient.location,
            requirements=triage_result["requirements"],
            top_n=5,
        )
        recommendations.recommendations = run_explanation_agent(recommendations.recommendations)

        if not recommendations.recommendations:
            continue

        selected = _choose_best_candidate(
            candidates=recommendations.recommendations,
            assigned_counts=assigned_counts,
            total_patients=len(patients),
        )

        if selected.compatibility != "full":
            fallback_count += 1

        selected_index = next((index for index, candidate in enumerate(recommendations.recommendations) if candidate.hospital_id == selected.hospital_id), 0)
        if selected_index != 0:
            recommendations.recommendations.insert(0, recommendations.recommendations.pop(selected_index))

        recommendations.recommendations[0].rank = 1
        recommendations.recommendations[0].score_label = "Batch Best"
        for index, candidate in enumerate(recommendations.recommendations[1:], start=2):
            candidate.rank = index
            candidate.score_label = "Batch Alternative"

        ambulance_assignment = assign_ambulance(case_id=patient.case_id, patient_location=patient.location)
        used_hospitals[selected.hospital_id] = used_hospitals.get(selected.hospital_id, 0) + 1
        assigned_counts[selected.hospital_id] = assigned_counts.get(selected.hospital_id, 0) + 1

        persist_batch_result(
            case_id=patient.case_id,
            severity=triage_result["severity_score"],
            urgency=patient.triage_output.urgency_level,
            specialist=triage_result["requirements"]["specialist"],
            recommendations=recommendations,
            ambulance_assignment=ambulance_assignment,
            selected_hospital_id=selected.hospital_id,
            events=[
                "CASE_CREATED",
                "TRIAGED",
                "RECOMMENDATION_GENERATED",
                "BATCH_ASSIGNED",
                "AMBULANCE_ASSIGNED" if ambulance_assignment else "AMBULANCE_NOT_ASSIGNED",
                "HOSPITAL_SELECTED",
                "HOSPITAL_NOTIFIED",
                "IN_TRANSIT",
                "ARRIVED",
            ],
            icu_decrement=1 if triage_result["requirements"]["ICU"] else 0,
            load_increment=5.0 if patient.triage_output.severity_score >= 8 else 3.0,
        )

        assignments.append(
            {
                "case_id": patient.case_id,
                "patient_id": patient.patient_id,
                "hospital_id": selected.hospital_id,
                "hospital_name": selected.hospital_name,
                "eta": selected.eta,
                "compatibility": selected.compatibility,
                "score": selected.score,
                "rank": selected.rank,
                "score_label": selected.score_label,
                "risk_flags": selected.risk_flags,
                "reason": selected.explanation,
                "ambulance": ambulance_assignment.model_dump() if ambulance_assignment else None,
            }
        )

    batch_summary = {
        "batch_id": f"batch-{_now_iso()}",
        "total_patients": len(patients),
        "assigned_patients": len(assignments),
        "fallback_used": fallback_count,
        "hospitals_used": len(used_hospitals),
        "load_balanced": len(used_hospitals) > 1,
        "message": "Patients distributed across multiple hospitals to prevent ICU overload and reduce treatment delay.",
    }

    return {
        "summary": batch_summary,
        "assignments": assignments,
    }