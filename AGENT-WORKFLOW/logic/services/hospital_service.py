from datetime import datetime, timezone
from typing import Dict, List, Tuple

from logic.models.hospital_model import HospitalDynamicModel, HospitalStaticModel
from logic.models.patient_model import CoordinatesModel
from logic.models.recommendation_model import (
    HospitalRecommendationItemModel,
    HospitalRecommendationModel,
    HospitalStateModel,
    ResourceMatchModel,
)
from logic.services.routing_service import compute_distance_km, compute_eta_minutes
from logic.utils.db_store import load_hospitals_with_status


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _dynamic_index(dynamic_data: List[HospitalDynamicModel]) -> Dict[str, HospitalDynamicModel]:
    return {item.hospital_id: item for item in dynamic_data}


def _map_db_rows_to_models(rows: List[Dict]) -> Tuple[List[HospitalStaticModel], List[HospitalDynamicModel]]:
    static_data: List[HospitalStaticModel] = []
    dynamic_data: List[HospitalDynamicModel] = []

    for row in rows:
        has_icu = bool(row.get("has_ICU"))
        available_icu = int(row.get("available_ICU_beds") or 0)
        load_percentage = float(row.get("current_load_percentage") or 0.0)
        intake_delay = int(row.get("avg_intake_delay") or 0)
        readiness = float(row.get("readiness_score") or 0.0)

        static_data.append(
            HospitalStaticModel(
                hospital_id=str(row["hospital_id"]),
                hospital_name=str(row.get("hospital_name") or "Unknown Hospital"),
                location=CoordinatesModel(
                    latitude=float(row.get("latitude") or 0.0),
                    longitude=float(row.get("longitude") or 0.0),
                ),
                facilities={
                    "has_ICU": has_icu,
                    "has_ventilator": has_icu,
                    "has_CT_scan": False,
                    "has_MRI": False,
                },
                specialists_available=["general", "cardiology", "trauma", "neuro"],
                capacity={
                    "max_ICU_beds": int(row.get("max_ICU_beds") or 0),
                    "max_ventilators": int(row.get("max_ICU_beds") or 0),
                    "max_general_beds": 0,
                },
                hospital_type=str(row.get("hospital_type") or "general"),
                avg_treatment_time=35,
            )
        )

        dynamic_data.append(
            HospitalDynamicModel(
                hospital_id=str(row["hospital_id"]),
                availability={
                    "available_ICU_beds": available_icu,
                    "available_ventilators": available_icu,
                    "available_general_beds": 0,
                },
                current_load_percentage=load_percentage,
                avg_intake_delay=intake_delay,
                status="full" if available_icu <= 0 else "open",
                staff_availability_score=readiness,
                readiness_score=readiness,
                last_updated_timestamp=str(row.get("last_updated_timestamp") or ""),
            )
        )

    return static_data, dynamic_data


def _compatibility(static_item: HospitalStaticModel, dynamic_item: HospitalDynamicModel, requirements: Dict) -> Tuple[str, ResourceMatchModel]:
    icu_match = (not requirements.get("ICU")) or (
        static_item.facilities.has_ICU and dynamic_item.availability.available_ICU_beds > 0
    )
    ventilator_match = (not requirements.get("ventilator")) or (
        static_item.facilities.has_ventilator and dynamic_item.availability.available_ventilators > 0
    )
    specialist_needed = requirements.get("specialist", "general")
    specialist_match = specialist_needed == "general" or specialist_needed in static_item.specialists_available

    matches = [icu_match, ventilator_match, specialist_match]
    score = sum(1 for m in matches if m)
    if score == 3 and dynamic_item.status == "open":
        level = "full"
    elif score >= 2 and dynamic_item.status in {"open", "emergency_only"}:
        level = "partial"
    else:
        level = "risky"

    return level, ResourceMatchModel(ICU=icu_match, ventilator=ventilator_match, specialist=specialist_match)


def _hospital_score(eta: int, load_percentage: float, intake_delay: int) -> float:
    return round((0.5 * eta) + (0.3 * load_percentage) + (0.2 * intake_delay), 2)


def recommend_hospitals(case_id: str, patient_location: CoordinatesModel, requirements: Dict, top_n: int = 3) -> HospitalRecommendationModel:
    db_rows = load_hospitals_with_status()
    static_data, dynamic_data = _map_db_rows_to_models(db_rows)
    dynamic_lookup = _dynamic_index(dynamic_data)

    candidates: List[HospitalRecommendationItemModel] = []

    for static_item in static_data:
        dynamic_item = dynamic_lookup.get(static_item.hospital_id)
        if dynamic_item is None:
            continue
        if dynamic_item.status == "full":
            continue

        compatibility, resource_match = _compatibility(static_item, dynamic_item, requirements)
        distance = compute_distance_km(patient_location, static_item.location)
        traffic = "high" if distance > 15 else "medium" if distance > 6 else "low"
        eta = compute_eta_minutes(distance_km=distance, speed_kmph=35.0, traffic_level=traffic)
        eta = max(eta, 9)
        score = _hospital_score(eta, dynamic_item.current_load_percentage, dynamic_item.avg_intake_delay)

        risk_flags: List[str] = []
        if compatibility != "full":
            risk_flags.append("partial_resource_match")
        if dynamic_item.current_load_percentage >= 55:
            risk_flags.append("er_load_moderate")
        if dynamic_item.current_load_percentage > 85:
            risk_flags.append("high_load")
        if dynamic_item.status == "emergency_only":
            risk_flags.append("restricted_intake")
        if dynamic_item.avg_intake_delay >= 10:
            risk_flags.append("intake_delay_present")
        if not risk_flags:
            risk_flags.append("minor_operational_variability")

        candidates.append(
            HospitalRecommendationItemModel(
                hospital_id=static_item.hospital_id,
                hospital_name=static_item.hospital_name,
                eta=eta,
                distance_km=distance,
                compatibility=compatibility,
                score=score,
                resource_match=resource_match,
                hospital_state=HospitalStateModel(
                    available_icu_beds=available_icu,
                    load_percentage=dynamic_item.current_load_percentage,
                    intake_delay=dynamic_item.avg_intake_delay,
                    readiness_score=dynamic_item.readiness_score,
                ),
                risk_flags=risk_flags,
            )
        )

    candidates.sort(key=lambda item: item.score)

    selected: List[HospitalRecommendationItemModel] = []
    if candidates:
        selected.append(candidates[0])

    fastest = min(candidates, key=lambda item: item.eta) if candidates else None
    if fastest is not None and all(item.hospital_id != fastest.hospital_id for item in selected):
        selected.append(fastest)

    safety_pool = [item for item in candidates if item.compatibility == "full"] or candidates
    safest = min(safety_pool, key=lambda item: (item.hospital_state.load_percentage, item.score)) if safety_pool else None
    if safest is not None and all(item.hospital_id != safest.hospital_id for item in selected):
        selected.append(safest)

    for item in candidates:
        if len(selected) >= top_n:
            break
        if all(existing.hospital_id != item.hospital_id for existing in selected):
            selected.append(item)

    selected = selected[:top_n]

    for index, item in enumerate(selected, start=1):
        item.rank = index
        if index == 1:
            item.score_label = "Best"
        elif index == 2:
            item.score_label = "Fast Alternative"
        else:
            item.score_label = "Safe Alternative"

    return HospitalRecommendationModel(
        case_id=case_id,
        generated_at=_now_iso(),
        recommendations=selected,
    )
