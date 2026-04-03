from datetime import datetime, timezone
from typing import List, Tuple

from logic.models.hospital_model import (
    HospitalAvailabilityModel,
    HospitalCapacityModel,
    HospitalDynamicModel,
    HospitalFacilitiesModel,
    HospitalStaticModel,
)
from logic.models.patient_model import CoordinatesModel


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_hospital_data() -> Tuple[List[HospitalStaticModel], List[HospitalDynamicModel]]:
    static_data = [
        HospitalStaticModel(
            hospital_id="H001",
            hospital_name="CityCare Central",
            location=CoordinatesModel(latitude=12.9716, longitude=77.5946),
            facilities=HospitalFacilitiesModel(has_ICU=True, has_ventilator=True, has_CT_scan=True, has_MRI=True),
            specialists_available=["cardiology", "neurology", "emergency"],
            capacity=HospitalCapacityModel(max_ICU_beds=30, max_ventilators=20, max_general_beds=200),
            hospital_type="multi_specialty",
            avg_treatment_time=40,
        ),
        HospitalStaticModel(
            hospital_id="H002",
            hospital_name="Metro Lifeline",
            location=CoordinatesModel(latitude=12.9352, longitude=77.6245),
            facilities=HospitalFacilitiesModel(has_ICU=True, has_ventilator=True, has_CT_scan=True, has_MRI=False),
            specialists_available=["orthopedics", "emergency"],
            capacity=HospitalCapacityModel(max_ICU_beds=20, max_ventilators=10, max_general_beds=120),
            hospital_type="general",
            avg_treatment_time=35,
        ),
        HospitalStaticModel(
            hospital_id="H003",
            hospital_name="Green Cross Hospital",
            location=CoordinatesModel(latitude=12.9279, longitude=77.6271),
            facilities=HospitalFacilitiesModel(has_ICU=False, has_ventilator=False, has_CT_scan=True, has_MRI=False),
            specialists_available=["general"],
            capacity=HospitalCapacityModel(max_ICU_beds=0, max_ventilators=0, max_general_beds=80),
            hospital_type="community",
            avg_treatment_time=30,
        ),
        HospitalStaticModel(
            hospital_id="H004",
            hospital_name="Apex Trauma Center",
            location=CoordinatesModel(latitude=12.9989, longitude=77.5713),
            facilities=HospitalFacilitiesModel(has_ICU=True, has_ventilator=True, has_CT_scan=True, has_MRI=True),
            specialists_available=["trauma", "surgery", "emergency"],
            capacity=HospitalCapacityModel(max_ICU_beds=25, max_ventilators=18, max_general_beds=150),
            hospital_type="trauma",
            avg_treatment_time=45,
        ),
        HospitalStaticModel(
            hospital_id="H005",
            hospital_name="Sunrise Medical",
            location=CoordinatesModel(latitude=12.9141, longitude=77.6453),
            facilities=HospitalFacilitiesModel(has_ICU=True, has_ventilator=False, has_CT_scan=True, has_MRI=False),
            specialists_available=["cardiology", "general"],
            capacity=HospitalCapacityModel(max_ICU_beds=10, max_ventilators=4, max_general_beds=90),
            hospital_type="general",
            avg_treatment_time=38,
        ),
        HospitalStaticModel(
            hospital_id="H006",
            hospital_name="NorthStar Emergency",
            location=CoordinatesModel(latitude=13.0155, longitude=77.6055),
            facilities=HospitalFacilitiesModel(has_ICU=True, has_ventilator=True, has_CT_scan=False, has_MRI=False),
            specialists_available=["emergency", "pulmonology"],
            capacity=HospitalCapacityModel(max_ICU_beds=12, max_ventilators=12, max_general_beds=70),
            hospital_type="emergency",
            avg_treatment_time=28,
        ),
        HospitalStaticModel(
            hospital_id="H007",
            hospital_name="RiverView Health",
            location=CoordinatesModel(latitude=12.8812, longitude=77.6011),
            facilities=HospitalFacilitiesModel(has_ICU=False, has_ventilator=False, has_CT_scan=False, has_MRI=False),
            specialists_available=["general"],
            capacity=HospitalCapacityModel(max_ICU_beds=0, max_ventilators=0, max_general_beds=60),
            hospital_type="community",
            avg_treatment_time=25,
        ),
        HospitalStaticModel(
            hospital_id="H008",
            hospital_name="RapidAid Institute",
            location=CoordinatesModel(latitude=12.9568, longitude=77.7012),
            facilities=HospitalFacilitiesModel(has_ICU=True, has_ventilator=True, has_CT_scan=True, has_MRI=True),
            specialists_available=["neurology", "cardiology", "surgery"],
            capacity=HospitalCapacityModel(max_ICU_beds=18, max_ventilators=15, max_general_beds=110),
            hospital_type="multi_specialty",
            avg_treatment_time=42,
        ),
        HospitalStaticModel(
            hospital_id="H009",
            hospital_name="PrimeCare South",
            location=CoordinatesModel(latitude=12.8721, longitude=77.5522),
            facilities=HospitalFacilitiesModel(has_ICU=True, has_ventilator=False, has_CT_scan=True, has_MRI=False),
            specialists_available=["orthopedics", "surgery"],
            capacity=HospitalCapacityModel(max_ICU_beds=8, max_ventilators=3, max_general_beds=75),
            hospital_type="general",
            avg_treatment_time=36,
        ),
        HospitalStaticModel(
            hospital_id="H010",
            hospital_name="Unity Health Hub",
            location=CoordinatesModel(latitude=12.9464, longitude=77.5800),
            facilities=HospitalFacilitiesModel(has_ICU=True, has_ventilator=True, has_CT_scan=False, has_MRI=False),
            specialists_available=["emergency", "cardiology"],
            capacity=HospitalCapacityModel(max_ICU_beds=14, max_ventilators=9, max_general_beds=95),
            hospital_type="emergency",
            avg_treatment_time=32,
        ),
        HospitalStaticModel(
            hospital_id="H011",
            hospital_name="Lakeside MultiCare",
            location=CoordinatesModel(latitude=12.9897, longitude=77.6721),
            facilities=HospitalFacilitiesModel(has_ICU=True, has_ventilator=True, has_CT_scan=True, has_MRI=False),
            specialists_available=["pulmonology", "cardiology"],
            capacity=HospitalCapacityModel(max_ICU_beds=16, max_ventilators=11, max_general_beds=100),
            hospital_type="multi_specialty",
            avg_treatment_time=39,
        ),
        HospitalStaticModel(
            hospital_id="H012",
            hospital_name="CareBridge Hospital",
            location=CoordinatesModel(latitude=13.0222, longitude=77.6402),
            facilities=HospitalFacilitiesModel(has_ICU=False, has_ventilator=True, has_CT_scan=False, has_MRI=False),
            specialists_available=["general", "pulmonology"],
            capacity=HospitalCapacityModel(max_ICU_beds=4, max_ventilators=6, max_general_beds=65),
            hospital_type="general",
            avg_treatment_time=34,
        ),
    ]

    dynamic_data = [
        HospitalDynamicModel(hospital_id="H001", availability=HospitalAvailabilityModel(available_ICU_beds=8, available_ventilators=5, available_general_beds=40), current_load_percentage=65.0, avg_intake_delay=12, status="open", staff_availability_score=0.82, readiness_score=0.88, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H002", availability=HospitalAvailabilityModel(available_ICU_beds=4, available_ventilators=2, available_general_beds=20), current_load_percentage=78.0, avg_intake_delay=18, status="open", staff_availability_score=0.74, readiness_score=0.79, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H003", availability=HospitalAvailabilityModel(available_ICU_beds=0, available_ventilators=0, available_general_beds=9), current_load_percentage=88.0, avg_intake_delay=22, status="open", staff_availability_score=0.65, readiness_score=0.62, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H004", availability=HospitalAvailabilityModel(available_ICU_beds=3, available_ventilators=2, available_general_beds=14), current_load_percentage=82.0, avg_intake_delay=20, status="emergency_only", staff_availability_score=0.73, readiness_score=0.75, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H005", availability=HospitalAvailabilityModel(available_ICU_beds=1, available_ventilators=0, available_general_beds=11), current_load_percentage=91.0, avg_intake_delay=24, status="open", staff_availability_score=0.61, readiness_score=0.58, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H006", availability=HospitalAvailabilityModel(available_ICU_beds=6, available_ventilators=6, available_general_beds=22), current_load_percentage=54.0, avg_intake_delay=10, status="open", staff_availability_score=0.86, readiness_score=0.9, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H007", availability=HospitalAvailabilityModel(available_ICU_beds=0, available_ventilators=0, available_general_beds=5), current_load_percentage=96.0, avg_intake_delay=30, status="full", staff_availability_score=0.4, readiness_score=0.35, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H008", availability=HospitalAvailabilityModel(available_ICU_beds=7, available_ventilators=5, available_general_beds=28), current_load_percentage=62.0, avg_intake_delay=14, status="open", staff_availability_score=0.84, readiness_score=0.87, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H009", availability=HospitalAvailabilityModel(available_ICU_beds=2, available_ventilators=0, available_general_beds=13), current_load_percentage=85.0, avg_intake_delay=21, status="open", staff_availability_score=0.68, readiness_score=0.66, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H010", availability=HospitalAvailabilityModel(available_ICU_beds=5, available_ventilators=3, available_general_beds=30), current_load_percentage=58.0, avg_intake_delay=11, status="open", staff_availability_score=0.81, readiness_score=0.84, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H011", availability=HospitalAvailabilityModel(available_ICU_beds=4, available_ventilators=2, available_general_beds=18), current_load_percentage=71.0, avg_intake_delay=16, status="open", staff_availability_score=0.77, readiness_score=0.8, last_updated_timestamp=_now_iso()),
        HospitalDynamicModel(hospital_id="H012", availability=HospitalAvailabilityModel(available_ICU_beds=0, available_ventilators=1, available_general_beds=12), current_load_percentage=80.0, avg_intake_delay=19, status="open", staff_availability_score=0.7, readiness_score=0.72, last_updated_timestamp=_now_iso()),
    ]

    return static_data, dynamic_data
