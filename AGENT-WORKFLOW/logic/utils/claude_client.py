import json
import os
from datetime import datetime, timezone
from typing import Any, Dict, List

from dotenv import load_dotenv

try:
    from anthropic import Anthropic
except Exception:
    Anthropic = None


load_dotenv()

DEFAULT_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-5-20250929")


def utc_iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _get_client() -> Any:
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key or Anthropic is None:
        return None
    return Anthropic(api_key=api_key)


def _safe_json_loads(value: str) -> Dict[str, Any]:
    parsed = json.loads(value)
    if isinstance(parsed, dict):
        return parsed
    return {}


def _to_bool(value: Any, default: bool) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        lowered = value.strip().lower()
        if lowered in {"true", "1", "yes"}:
            return True
        if lowered in {"false", "0", "no"}:
            return False
    if isinstance(value, int):
        return bool(value)
    return default


def _to_float(value: Any, default: float) -> float:
    try:
        return float(value)
    except Exception:
        return default


def _canonical_symptom(value: Any) -> str:
    normalized = str(value).strip().lower().replace("-", " ").replace("_", " ")
    normalized = " ".join(normalized.split())
    mapping = {
        "chest pain": "chest_pain",
        "pain": "pain",
        "unconscious": "unconsciousness",
        "unconsciousness": "unconsciousness",
        "not breathing": "breathing_issue",
        "absence of breathing": "breathing_issue",
        "breathing issue": "breathing_issue",
        "breathlessness": "breathing_issue",
        "shortness of breath": "breathing_issue",
        "fever": "fever",
        "cough": "cough",
        "bleeding": "bleeding",
    }
    return mapping.get(normalized, normalized.replace(" ", "_"))


def _tokenize(text: str) -> List[str]:
    normalized = text.lower().replace(",", " ").replace(".", " ")
    return [token.strip() for token in normalized.split() if token.strip()]


def _heuristic_extract(input_text: str) -> Dict[str, Any]:
    tokens = _tokenize(input_text)
    symptoms: List[str] = []

    if "chest" in tokens and "pain" in tokens:
        symptoms.append("chest_pain")
    if "breathing" in tokens or "breath" in tokens or ("not" in tokens and ("breathing" in tokens or "breath" in tokens)):
        symptoms.append("breathing_issue")
    if "unconscious" in tokens:
        symptoms.append("unconsciousness")
    if "fever" in tokens:
        symptoms.append("fever")
    if "cough" in tokens:
        symptoms.append("cough")
    if "bleeding" in tokens:
        symptoms.append("bleeding")

    not_breathing = "not" in tokens and ("breathing" in tokens or "breath" in tokens)
    unconscious = "unconscious" in tokens
    bleeding = "bleeding" in tokens

    return {
        "case_id": "case-" + str(abs(hash(input_text)) % 10_000_000),
        "patient_id": "unknown",
        "source_type": "public",
        "timestamp": utc_iso_now(),
        "demographics": {"age": 0, "gender": "unknown", "weight": 0.0},
        "location": {"latitude": 12.9321, "longitude": 77.6179},
        "vitals": {
            "heart_rate": 0,
            "systolic_bp": 0,
            "diastolic_bp": 0,
            "spo2": 88.0 if not_breathing else 96.0,
            "respiratory_rate": 8 if not_breathing else 16,
            "temperature": 38.0 if "fever" in tokens else 36.8,
        },
        "condition_flags": {
            "conscious": not unconscious,
            "breathing": not not_breathing,
            "bleeding": bleeding,
        },
        "symptoms": sorted(set(symptoms)),
        "injury_type": "unknown",
        "pain_level": 8 if "chest" in tokens or "pain" in tokens else 2,
        "time_since_incident": 10,
        "medical_context": {"history": [], "allergies": []},
        "triage_output": {
            "severity_score": 0,
            "urgency_level": "low",
            "needs_ICU": False,
            "needs_ventilator": False,
            "needs_surgery": False,
            "required_specialist": "general",
            "estimated_time_to_critical": 0,
        },
    }


def _normalize_extracted_payload(payload: Dict[str, Any], fallback: Dict[str, Any]) -> Dict[str, Any]:
    merged = dict(fallback)
    merged.update({key: payload.get(key, merged.get(key)) for key in merged.keys()})

    location = payload.get("location") if isinstance(payload.get("location"), dict) else {}
    lat = _to_float(location.get("latitude"), fallback["location"]["latitude"])
    lon = _to_float(location.get("longitude"), fallback["location"]["longitude"])
    if lat == 0.0 and lon == 0.0:
        lat = fallback["location"]["latitude"]
        lon = fallback["location"]["longitude"]
    merged["location"] = {"latitude": lat, "longitude": lon}

    symptoms = payload.get("symptoms")
    if isinstance(symptoms, list):
        canonical: List[str] = []
        for symptom in symptoms:
            candidate = _canonical_symptom(symptom)
            if candidate in {"chest_pain", "breathing_issue", "unconsciousness", "fever", "cough", "bleeding", "pain"}:
                canonical.append(candidate)
        merged["symptoms"] = sorted(set(canonical)) if canonical else fallback["symptoms"]
    else:
        merged["symptoms"] = fallback["symptoms"]

    flags = payload.get("condition_flags") if isinstance(payload.get("condition_flags"), dict) else {}
    merged["condition_flags"] = {
        "conscious": _to_bool(flags.get("conscious"), fallback["condition_flags"]["conscious"]),
        "breathing": _to_bool(flags.get("breathing"), fallback["condition_flags"]["breathing"]),
        "bleeding": _to_bool(flags.get("bleeding"), fallback["condition_flags"]["bleeding"]),
    }

    if "unconsciousness" in merged["symptoms"]:
        merged["condition_flags"]["conscious"] = False
    if "breathing_issue" in merged["symptoms"]:
        merged["condition_flags"]["breathing"] = False
    if "bleeding" in merged["symptoms"]:
        merged["condition_flags"]["bleeding"] = True

    return merged


def extract_structured_data(input_text: str) -> Dict[str, Any]:
    fallback = _heuristic_extract(input_text)
    client = _get_client()
    if client is not None:
        prompt = (
            "Extract strict JSON with fields case_id, patient_id, source_type, timestamp, demographics, "
            "location, vitals, condition_flags, symptoms, injury_type, pain_level, time_since_incident, "
            "medical_context, triage_output. Do not include markdown. Use null or safe defaults for missing fields. "
            f"Patient text: {input_text}"
        )
        response = client.messages.create(
            model=DEFAULT_MODEL,
            max_tokens=800,
            temperature=0,
            messages=[{"role": "user", "content": prompt}],
        )
        content = "".join(
            block.text for block in response.content if getattr(block, "type", "") == "text"
        ).strip()
        try:
            return _normalize_extracted_payload(_safe_json_loads(content), fallback)
        except Exception:
            pass

    return fallback


def interpret_triage_context(symptoms: List[str], condition_flags: Dict[str, bool]) -> Dict[str, List[str]]:
    suspected_conditions: List[str] = []
    risk_flags: List[str] = []

    if "chest_pain" in symptoms:
        suspected_conditions.append("cardiac_event")
    if "breathing_issue" in symptoms:
        suspected_conditions.append("respiratory_distress")
    if "fever" in symptoms:
        suspected_conditions.append("infection_risk")
    if not condition_flags.get("conscious", True):
        risk_flags.append("unconscious")
    if not condition_flags.get("breathing", True):
        risk_flags.append("airway_compromise")
    if condition_flags.get("bleeding", False):
        risk_flags.append("active_bleeding")

    return {
        "suspected_conditions": sorted(set(suspected_conditions)),
        "risk_flags": sorted(set(risk_flags)),
    }


def generate_recommendation_text(item: Dict[str, Any]) -> Dict[str, Any]:
    client = _get_client()
    if client is not None:
        prompt = (
            "Given only the provided hospital recommendation JSON, produce strict JSON with keys pros, cons, "
            "and explanation. Use only the supplied data and do not hallucinate. Input: "
            f"{json.dumps(item, ensure_ascii=True)}"
        )
        response = client.messages.create(
            model=DEFAULT_MODEL,
            max_tokens=400,
            temperature=0,
            messages=[{"role": "user", "content": prompt}],
        )
        content = "".join(
            block.text for block in response.content if getattr(block, "type", "") == "text"
        ).strip()
        try:
            parsed = _safe_json_loads(content)
            if {"pros", "cons", "explanation"}.issubset(parsed):
                return parsed
        except Exception:
            pass

    pros = list(item.get("pros") or [])
    cons = list(item.get("cons") or [])

    if item.get("resource_match", {}).get("ICU") and item.get("resource_match", {}).get("ventilator"):
        pros.append("ICU and ventilator support available for critical care")
    elif item.get("resource_match", {}).get("ICU"):
        pros.append("ICU support available")
    elif item.get("resource_match", {}).get("ventilator"):
        pros.append("Ventilator support available")
    if item.get("hospital_state", {}).get("readiness_score", 0) >= 0.75:
        pros.append("High treatment readiness")

    load_percentage = item.get("hospital_state", {}).get("load_percentage", 0)
    intake_delay = item.get("hospital_state", {}).get("intake_delay", 0)
    if load_percentage >= 80:
        cons.append(f"High ER load ({int(load_percentage)}%) may delay handoff")
    elif load_percentage >= 55:
        cons.append(f"Moderate ER load ({int(load_percentage)}%) may cause slight delay")
    else:
        cons.append("Normal triage queue may add minor wait")

    if intake_delay >= 20:
        cons.append(f"Intake delay is elevated at {int(intake_delay)} minutes")
    elif intake_delay >= 10:
        cons.append(f"Estimated intake delay is around {int(intake_delay)} minutes")

    pros = pros[:2] if len(pros) >= 2 else (pros + ["Reasonable access"])[0:2]
    cons = cons[:2]

    explanation = (
        f"Selected because {item.get('hospital_name', 'Hospital')} provides required resources with "
        f"compatibility {item.get('compatibility', 'risky')}, estimated ETA {item.get('eta', 0)} minutes, "
        f"and readiness score {item.get('hospital_state', {}).get('readiness_score', 0)}."
    )

    return {
        "pros": pros,
        "cons": cons,
        "explanation": explanation,
    }
