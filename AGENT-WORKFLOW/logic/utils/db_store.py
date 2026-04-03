import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.parse import unquote, urlparse

import mysql.connector
from dotenv import load_dotenv
import os

from logic.models.ambulance_model import AmbulanceAssignmentModel
from logic.models.patient_model import PatientEmergencyModel
from logic.models.recommendation_model import HospitalRecommendationModel


ROOT_ENV = Path(__file__).resolve().parents[2] / ".env"
load_dotenv(ROOT_ENV)


def _db_config() -> Dict[str, Any]:
    database_link = os.getenv("DATABASE_LINK", "mysql://root:@127.0.0.1:3306/JIVAN")
    parsed = urlparse(database_link)
    return {
        "host": parsed.hostname or "127.0.0.1",
        "port": parsed.port or 3306,
        "user": unquote(parsed.username or "root"),
        "password": unquote(parsed.password or ""),
        "database": (parsed.path or "/JIVAN").lstrip("/"),
        "autocommit": False,
    }


def get_connection() -> mysql.connector.MySQLConnection:
    return mysql.connector.connect(**_db_config())


def _to_iso(value: Any) -> str:
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return str(value or "")


def load_latest_patient_case() -> PatientEmergencyModel:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        """
        SELECT ec.case_id, ec.patient_id, ec.source_type, ec.timestamp, ec.latitude, ec.longitude,
               ec.spo2, ec.systolic_bp, ec.severity_score, ec.urgency_level, ec.required_specialist,
               p.age, p.gender
        FROM emergency_cases ec
        JOIN patients p ON p.patient_id = ec.patient_id
        ORDER BY ec.timestamp DESC
        LIMIT 1
        """
    )
    row = cursor.fetchone()
    cursor.close()
    conn.close()

    if row is None:
        raise RuntimeError("No emergency case found in database")

    severity = int(row.get("severity_score") or 0)
    spo2 = float(row.get("spo2") or 0)
    systolic_bp = int(row.get("systolic_bp") or 0)
    specialist = str(row.get("required_specialist") or "general")

    symptoms: List[str] = []
    if specialist in {"cardio", "cardiology"}:
        symptoms.append("chest_pain")
    if spo2 < 90:
        symptoms.append("breathing_issue")
    if severity >= 8:
        symptoms.append("unconsciousness")

    urgency_map = {"low": "low", "medium": "medium", "high": "high", "critical": "critical"}
    urgency_value = urgency_map.get(str(row.get("urgency_level") or "").lower(), "medium")

    payload = {
        "case_id": str(row["case_id"]),
        "patient_id": str(row["patient_id"]),
        "source_type": str(row.get("source_type") or "ambulance"),
        "timestamp": _to_iso(row.get("timestamp")),
        "demographics": {
            "age": int(row.get("age") or 0),
            "gender": str(row.get("gender") or "unknown"),
            "weight": 0.0,
        },
        "location": {
            "latitude": float(row.get("latitude") or 0.0),
            "longitude": float(row.get("longitude") or 0.0),
        },
        "vitals": {
            "heart_rate": 0,
            "systolic_bp": systolic_bp,
            "diastolic_bp": int(systolic_bp * 0.65) if systolic_bp else 0,
            "spo2": spo2,
            "respiratory_rate": 10 if spo2 < 90 else 16,
            "temperature": 36.9,
        },
        "condition_flags": {
            "conscious": severity < 9,
            "breathing": spo2 >= 90,
            "bleeding": False,
        },
        "symptoms": sorted(set(symptoms)),
        "injury_type": "medical_emergency",
        "pain_level": 8 if "chest_pain" in symptoms else 4,
        "time_since_incident": 10,
        "medical_context": {"history": [], "allergies": []},
        "triage_output": {
            "severity_score": severity,
            "urgency_level": urgency_value,
            "needs_ICU": severity >= 8,
            "needs_ventilator": spo2 < 88,
            "needs_surgery": False,
            "required_specialist": specialist,
            "estimated_time_to_critical": 15 if severity >= 8 else 45,
        },
    }

    return PatientEmergencyModel(**payload)


def load_hospitals_with_status() -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        """
        SELECT h.hospital_id, h.hospital_name, h.latitude, h.longitude, h.hospital_type,
               h.has_ICU, h.max_ICU_beds,
               ds.available_ICU_beds, ds.current_load_percentage, ds.avg_intake_delay,
               ds.readiness_score, ds.last_updated_timestamp
        FROM hospitals h
        JOIN hospital_dynamic_status ds ON ds.hospital_id = h.hospital_id
        """
    )
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return rows


def load_ambulances() -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        """
        SELECT ambulance_id, latitude, longitude, status, last_updated_timestamp
        FROM ambulances
        """
    )
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return rows


def load_hospital_coordinates(hospital_id: str) -> Optional[Dict[str, float]]:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        """
        SELECT latitude, longitude
        FROM hospitals
        WHERE hospital_id = %s
        LIMIT 1
        """,
        (hospital_id,),
    )
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    if row is None:
        return None
    return {"latitude": float(row["latitude"]), "longitude": float(row["longitude"])}


def persist_core_outputs(
    case_id: str,
    severity: int,
    urgency: str,
    needs_icu: bool,
    specialist: str,
    recommendations: HospitalRecommendationModel,
    ambulance_assignment: Optional[AmbulanceAssignmentModel],
    events: List[str],
) -> None:
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        INSERT INTO triage (case_id, severity, urgency, needs_icu, specialist)
        VALUES (%s, %s, %s, %s, %s)
        """,
        (case_id, severity, urgency, int(needs_icu), specialist),
    )

    cursor.execute("DELETE FROM recommendations WHERE case_id = %s", (case_id,))
    for rec in recommendations.recommendations:
        cursor.execute(
            """
            INSERT INTO recommendations (case_id, hospital_id, eta, score, compatibility)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (case_id, rec.hospital_id, rec.eta, rec.score, rec.compatibility),
        )

    if ambulance_assignment is not None:
        cursor.execute("DELETE FROM ambulance_assignment WHERE case_id = %s", (case_id,))
        cursor.execute(
            """
            INSERT INTO ambulance_assignment (case_id, ambulance_id, eta_to_patient)
            VALUES (%s, %s, %s)
            """,
            (case_id, ambulance_assignment.ambulance_id, ambulance_assignment.eta_to_patient),
        )

    now_value = datetime.now(timezone.utc).replace(tzinfo=None)
    for event in events:
        cursor.execute(
            """
            INSERT INTO event_logs (event_id, case_id, event, timestamp)
            VALUES (%s, %s, %s, %s)
            """,
            (f"ev_{uuid.uuid4().hex[:16]}", case_id, event, now_value),
        )

    conn.commit()
    cursor.close()
    conn.close()