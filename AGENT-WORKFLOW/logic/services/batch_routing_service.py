import math
from datetime import datetime, timezone
from typing import Dict, List, Optional, Set

from logic.agents.explanation_agent import run_explanation_agent
from logic.models.ambulance_model import AmbulanceAssignmentModel
from logic.models.patient_model import PatientEmergencyModel
from logic.models.recommendation_model import HospitalRecommendationItemModel, HospitalRecommendationModel
from logic.services.ambulance_service import assign_ambulance
from logic.services.hospital_service import recommend_hospitals
from logic.services.triage_service import evaluate_triage
from logic.utils.db_store import load_critical_batch_patients, persist_batch_result

# Lower score = better (ETA + load + delay weighted sum)
_PARTIAL_COMPATIBILITY_PENALTY = 20.0
_RISKY_COMPATIBILITY_PENALTY   = 40.0


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _batch_penalty(
    candidate: HospitalRecommendationItemModel,
    assigned_count: int,
    total_patients: int,
    max_per_hospital: int,
) -> float:
    """
    Returns a penalty added to a hospital's base score to bias against
    overloaded or already-saturated hospitals during batch assignment.
    Higher penalty = less likely to be chosen.
    """
    # Penalise high ER load proportionally
    load_penalty = (candidate.hospital_state.load_percentage / 100.0) * 10.0

    # Penalise scarce ICU capacity — protect last beds for critical patients
    icu = candidate.hospital_state.available_icu_beds
    capacity_penalty = 0.0
    if icu <= 0:
        capacity_penalty += 35.0       # Full — only use as last resort
    elif icu == 1:
        capacity_penalty += 20.0       # Reserve for highest severity
    elif icu == 2:
        capacity_penalty += 8.0

    # Penalise intake delays
    if candidate.hospital_state.intake_delay >= 15:
        capacity_penalty += 10.0
    elif candidate.hospital_state.intake_delay >= 10:
        capacity_penalty += 5.0

    # Compatibility penalty — strongly discourage partial/risky assignments
    if candidate.compatibility == "partial":
        capacity_penalty += _PARTIAL_COMPATIBILITY_PENALTY
    elif candidate.compatibility == "risky":
        capacity_penalty += _RISKY_COMPATIBILITY_PENALTY

    # Saturation penalty — spread load across hospitals
    saturation_ratio = assigned_count / max(max_per_hospital, 1)
    saturation_penalty = saturation_ratio * 14.0
    if assigned_count >= max_per_hospital:
        saturation_penalty += 25.0    # Hard discourage — cap is about to be hit

    return load_penalty + capacity_penalty + saturation_penalty


def _choose_best_candidate(
    candidates: List[HospitalRecommendationItemModel],
    assigned_counts: Dict[str, int],
    total_patients: int,
    max_per_hospital: int,
) -> Optional[HospitalRecommendationItemModel]:
    """
    Re-rank candidates using batch-aware scoring and return the best pick.
    Preference order: full compatibility with ICU → partial → risky.
    Returns None only if all candidates are at hard cap.
    """
    ranked: List[tuple] = []
    for c in candidates:
        adjusted = c.score + _batch_penalty(
            candidate=c,
            assigned_count=assigned_counts.get(c.hospital_id, 0),
            total_patients=total_patients,
            max_per_hospital=max_per_hospital,
        )
        ranked.append((adjusted, c))

    ranked.sort(key=lambda item: (
        item[0],
        item[1].eta,
        -item[1].hospital_state.readiness_score,
    ))

    # Prefer full match with available ICU
    for _, c in ranked:
        if assigned_counts.get(c.hospital_id, 0) < max_per_hospital:
            if c.compatibility == "full" and c.hospital_state.available_icu_beds > 0:
                return c

    # Fallback: partial match with any ICU remaining
    for _, c in ranked:
        if assigned_counts.get(c.hospital_id, 0) < max_per_hospital:
            if c.compatibility == "partial" and c.hospital_state.available_icu_beds > 0:
                return c

    # Last resort: anything under cap
    for _, c in ranked:
        if assigned_counts.get(c.hospital_id, 0) < max_per_hospital:
            return c

    # All hospitals at cap — return best overall (overflow case)
    return ranked[0][1] if ranked else None


def assign_patients_batch(batch_size: int = 5) -> Dict:
    patients = load_critical_batch_patients(limit=batch_size)

    # Sort by severity DESC then time_to_critical ASC — most critical goes first
    patients.sort(key=lambda p: (
        -p.triage_output.severity_score,
        p.triage_output.estimated_time_to_critical,
    ))

    # Max patients any single hospital can absorb (40% rule)
    num_hospitals_estimate = 7   # from our seed data
    max_per_hospital = max(1, math.ceil(len(patients) * 0.40))

    assignments: List[Dict] = []
    assigned_counts: Dict[str, int] = {}   # hospital_id → patients assigned
    used_ambulances: Set[str] = set()      # prevent same ambulance for two patients
    hospital_distribution: Dict[str, str] = {}   # hospital_id → hospital_name
    fallback_count = 0

    for patient in patients:
        triage_context = {
            "suspected_conditions": (
                ["cardiac_event"] if "chest_pain" in patient.symptoms
                else ["respiratory_distress"] if "breathing_issue" in patient.symptoms
                else []
            ),
            "risk_flags": ["unconscious"] if not patient.condition_flags.conscious else [],
        }
        triage_result = evaluate_triage(patient, triage_context)

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
            max_per_hospital=max_per_hospital,
        )
        if selected is None:
            continue

        if selected.compatibility != "full":
            fallback_count += 1

        # Move selected to front and re-label ranks
        recs = recommendations.recommendations
        idx = next((i for i, c in enumerate(recs) if c.hospital_id == selected.hospital_id), 0)
        if idx != 0:
            recs.insert(0, recs.pop(idx))
        recs[0].rank = 1
        recs[0].score_label = "Batch Best"
        for i, c in enumerate(recs[1:], start=2):
            c.rank = i
            c.score_label = "Batch Alternative"

        # Assign nearest ambulance not already used in this batch
        ambulance_assignment = assign_ambulance(
            case_id=patient.case_id,
            patient_location=patient.location,
            exclude_ids=used_ambulances,
        )
        if ambulance_assignment:
            used_ambulances.add(ambulance_assignment.ambulance_id)

        assigned_counts[selected.hospital_id] = assigned_counts.get(selected.hospital_id, 0) + 1
        hospital_distribution[selected.hospital_id] = selected.hospital_name

        persist_batch_result(
            case_id=patient.case_id,
            severity=triage_result["severity_score"],
            urgency=patient.triage_output.urgency_level,
            specialist=triage_result["requirements"]["specialist"],
            recommendations=recommendations,
            ambulance_assignment=ambulance_assignment,
            selected_hospital_id=selected.hospital_id,
            events=[
                "CASE_CREATED", "TRIAGED", "RECOMMENDATION_GENERATED",
                "BATCH_ASSIGNED",
                "AMBULANCE_ASSIGNED" if ambulance_assignment else "AMBULANCE_NOT_ASSIGNED",
                "HOSPITAL_SELECTED", "HOSPITAL_NOTIFIED", "IN_TRANSIT", "ARRIVED",
            ],
            icu_decrement=1 if triage_result["requirements"]["ICU"] else 0,
            load_increment=5.0 if patient.triage_output.severity_score >= 8 else 3.0,
        )

        assignments.append({
            "case_id": patient.case_id,
            "patient_id": patient.patient_id,
            "severity": triage_result["severity_score"],
            "urgency": patient.triage_output.urgency_level,
            "hospital_id": selected.hospital_id,
            "hospital_name": selected.hospital_name,
            "eta_minutes": selected.eta,
            "distance_km": selected.distance_km,
            "compatibility": selected.compatibility,
            "score": round(selected.score, 2),
            "score_label": selected.score_label,
            "hospital_state": {
                "remaining_icu": selected.hospital_state.available_icu_beds,
                "load_percentage": selected.hospital_state.load_percentage,
                "intake_delay_min": selected.hospital_state.intake_delay,
                "readiness_score": selected.hospital_state.readiness_score,
            },
            "risk_flags": selected.risk_flags,
            "reason": selected.explanation,
            "ambulance": ambulance_assignment.model_dump() if ambulance_assignment else None,
        })

    # Build a human-readable batch summary
    num_hospitals = len(hospital_distribution)
    full_matches = len(assignments) - fallback_count
    dist_lines = ", ".join(
        f"{name}: {assigned_counts[hid]} patient{'s' if assigned_counts[hid] > 1 else ''}"
        for hid, name in hospital_distribution.items()
    )
    batch_message = (
        f"{len(assignments)} patient{'s' if len(assignments) != 1 else ''} distributed across "
        f"{num_hospitals} hospital{'s' if num_hospitals != 1 else ''}. "
        f"{full_matches} received full-compatibility assignments. "
        f"{fallback_count} assigned to partial-match hospitals due to capacity constraints. "
        f"No hospital exceeded {int(max_per_hospital / max(len(patients), 1) * 100)}% of batch load. "
        f"Distribution: {dist_lines}."
    )

    return {
        "summary": {
            "batch_id": f"batch-{_now_iso()}",
            "total_patients": len(patients),
            "assigned_patients": len(assignments),
            "full_match_assignments": full_matches,
            "fallback_used": fallback_count,
            "hospitals_used": num_hospitals,
            "load_balanced": num_hospitals > 1,
            "max_per_hospital_cap": max_per_hospital,
            "hospital_distribution": {
                hid: {"name": hospital_distribution[hid], "patients_assigned": cnt}
                for hid, cnt in assigned_counts.items()
            },
            "message": batch_message,
        },
        "assignments": assignments,
    }
