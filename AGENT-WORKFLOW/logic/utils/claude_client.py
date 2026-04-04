import json
import logging
import os
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv

try:
    from anthropic import Anthropic
except Exception:
    Anthropic = None

logger = logging.getLogger(__name__)

load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".env"), override=True)

# Strip possible \r from Windows-style .env line endings
DEFAULT_MODEL = (os.getenv("ANTHROPIC_MODEL") or "claude-3-haiku-20240307").strip()
FAST_MODEL = (os.getenv("ANTHROPIC_FAST_MODEL") or "claude-3-haiku-20240307").strip()


def utc_iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _get_client() -> Any:
    api_key = (os.getenv("ANTHROPIC_API_KEY") or "").strip()
    if not api_key or Anthropic is None:
        logger.warning(f"[CLIENT] Cannot create Anthropic client: key={'present' if api_key else 'MISSING'}, sdk={'loaded' if Anthropic else 'MISSING'}")
        return None
    return Anthropic(api_key=api_key)


def _safe_json_loads(value: str) -> Dict[str, Any]:
    # Strip markdown fences Claude sometimes wraps responses in
    stripped = value.strip()
    if stripped.startswith("```"):
        lines = stripped.splitlines()
        stripped = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:]).strip()
    parsed = json.loads(stripped)
    if isinstance(parsed, dict):
        return parsed
    return {}


def _safe_json_loads_list(value: str) -> List[Dict[str, Any]]:
    stripped = value.strip()
    if stripped.startswith("```"):
        lines = stripped.splitlines()
        stripped = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:]).strip()

    # Sometimes the model adds prose around the JSON array.
    if not stripped.startswith("["):
        start = stripped.find("[")
        end = stripped.rfind("]")
        if start != -1 and end != -1 and end > start:
            stripped = stripped[start:end + 1]

    parsed = json.loads(stripped)
    if isinstance(parsed, list):
        return [item for item in parsed if isinstance(item, dict)]
    return []


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


def _augment_symptoms_from_text(payload: Dict[str, Any], input_text: str) -> Dict[str, Any]:
    tokens = _tokenize(input_text)
    joined = " ".join(tokens)

    symptoms = payload.get("symptoms") if isinstance(payload.get("symptoms"), list) else []
    canonical = {str(s).strip().lower() for s in symptoms if s}

    if "dizziness" in tokens or "giddiness" in tokens or "vertigo" in tokens:
        canonical.add("dizziness")
    if "vomiting" in tokens or "vomit" in tokens or "nausea" in tokens:
        canonical.add("vomiting")
    if "cant walk straight" in joined or "cannot walk straight" in joined or "walk straight" in joined:
        canonical.add("ataxia")

    payload["symptoms"] = sorted(canonical)
    return payload


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
    if "dizziness" in tokens or "giddiness" in tokens or "vertigo" in tokens:
        symptoms.append("dizziness")
    if "vomiting" in tokens or "vomit" in tokens or "nausea" in tokens:
        symptoms.append("vomiting")

    joined = " ".join(tokens)
    if "cant walk straight" in joined or "cannot walk straight" in joined or "walk straight" in joined:
        symptoms.append("ataxia")

    not_breathing = "not" in tokens and ("breathing" in tokens or "breath" in tokens)
    unconscious = "unconscious" in tokens
    bleeding = "bleeding" in tokens

    return {
        "case_id": f"case-{uuid.uuid4().hex[:8]}",
        "patient_id": "unknown",
        "source_type": "public",
        "timestamp": utc_iso_now(),
        "demographics": {"age": 0, "gender": "unknown", "weight": 0.0},
        "location": {"latitude": 18.518, "longitude": 73.815},
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
    # Always use the heuristic case_id — Claude guesses generic IDs like "CASE-001"
    merged["case_id"] = fallback["case_id"]

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
            if candidate in {
                "chest_pain", "breathing_issue", "unconsciousness", "fever", "cough", "bleeding", "pain",
                "dizziness", "vomiting", "ataxia",
            }:
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
        try:
            prompt = (
                "Extract strict JSON with fields case_id, patient_id, source_type, timestamp, demographics, "
                "location, vitals, condition_flags, symptoms, injury_type, pain_level, time_since_incident, "
                "medical_context, triage_output. Do not include markdown. Use null or safe defaults for missing fields. "
                f"Patient text: {input_text}"
            )
            response = client.messages.create(
                model=DEFAULT_MODEL,
                max_tokens=500,
                temperature=0,
                messages=[{"role": "user", "content": prompt}],
            )
            content = "".join(
                block.text for block in response.content if getattr(block, "type", "") == "text"
            ).strip()
            normalized = _normalize_extracted_payload(_safe_json_loads(content), fallback)
            return _augment_symptoms_from_text(normalized, input_text)
        except Exception as exc:
            logger.warning(f"[EXTRACT] Claude call failed (model={DEFAULT_MODEL}): {exc}")

    return _augment_symptoms_from_text(fallback, input_text)


def interpret_triage_context(symptoms: List[str], condition_flags: Dict[str, bool]) -> Dict[str, List[str]]:
    suspected_conditions: List[str] = []
    risk_flags: List[str] = []

    if "chest_pain" in symptoms:
        suspected_conditions.append("cardiac_event")
    if "breathing_issue" in symptoms:
        suspected_conditions.append("respiratory_distress")
    if "fever" in symptoms:
        suspected_conditions.append("infection_risk")
    if any(s in symptoms for s in ["dizziness", "vomiting", "ataxia"]):
        suspected_conditions.append("neurologic_event")
    if not condition_flags.get("conscious", True):
        risk_flags.append("unconscious")
    if not condition_flags.get("breathing", True):
        risk_flags.append("airway_compromise")
    if condition_flags.get("bleeding", False):
        risk_flags.append("active_bleeding")
    if "ataxia" in symptoms:
        risk_flags.append("neurologic_deficit")
    if "dizziness" in symptoms and "vomiting" in symptoms:
        risk_flags.append("possible_stroke")

    return {
        "suspected_conditions": sorted(set(suspected_conditions)),
        "risk_flags": sorted(set(risk_flags)),
    }


_BLOCKCHAIN_DIAGNOSTIC_SYSTEM_PROMPT = (
    "You are a real-time Emergency Diagnostic Router. Speed is critical. "
    "Correlate live symptoms with blockchain history. Prioritize recurrent events over new diagnoses. "
    "Output ONLY compact JSON — no markdown, no extra text:\n"
    '{"primary_diagnosis":"string","blockchain_correlation":"one-line: which past block caused this",'
    '"mechanism_of_injury":"one-line mechanism","routing_priority":"Critical|High|Low",'
    '"severity":<1-10>,"required_specialist":"string"}'
)

_DIAGNOSTIC_SYSTEM_PROMPT = (
    "You are a real-time Emergency Diagnostic Router. Speed is critical. "
    "Output ONLY compact JSON — no markdown, no extra text:\n"
    '{"diagnosis":"short clinical label","diagnosis_reasoning":"one-line reasoning linking vitals/symptoms to diagnosis",'
    '"severity":<1-10>,"required_specialist":"string"}'
)


def run_diagnostic_agent(
    symptoms: List[str],
    condition_flags: Dict[str, bool],
    vitals: Dict[str, Any],
    medical_history: Dict[str, Any],
    scene_context: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Calls Claude as a Senior ER Physician to produce a probable diagnosis,
    severity score, and required specialist informed by the patient's history
    and optional scene photograph evidence.
    Returns an empty dict if the LLM is unavailable or returns invalid JSON.
    """
    client = _get_client()
    if client is None:
        return {}

    payload: Dict[str, Any] = {
        "current_symptoms": symptoms,
        "condition_flags": condition_flags,
        "vitals": vitals,
        "medical_history": medical_history,
    }
    scene_text = format_scene_as_diagnostic_context(scene_context) if scene_context else ""
    user_content = (scene_text + "\n\n" if scene_text else "") + json.dumps(payload, ensure_ascii=True)

    try:
        response = client.messages.create(
            model=DEFAULT_MODEL,
            max_tokens=150,
            temperature=0,
            system=_DIAGNOSTIC_SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_content}],
        )
        content = "".join(
            block.text for block in response.content if getattr(block, "type", "") == "text"
        ).strip()
        parsed = _safe_json_loads(content)
        if isinstance(parsed, dict) and parsed.get("diagnosis"):
            severity_raw = parsed.get("severity", 5)
            try:
                severity_value = int(severity_raw)
            except Exception:
                severity_value = 5
            specialist = str(parsed.get("required_specialist") or "general").strip().lower()
            if specialist in {"none", "null", "n/a", "na", "unknown", ""}:
                specialist = "general"

            return {
                "diagnosis": str(parsed["diagnosis"]),
                "diagnosis_reasoning": str(parsed.get("diagnosis_reasoning") or "Clinical context suggests this diagnosis."),
                "diagnosis_severity": min(10, max(1, severity_value)),
                "required_specialist": specialist,
            }
        logger.warning(f"[DIAGNOSTIC] Missing fields in response: {list(parsed.keys())}")
    except Exception as exc:
        logger.error(f"[DIAGNOSTIC] Claude call failed: {exc}")

    return {}


def run_blockchain_diagnostic_agent(
    symptoms: List[str],
    vitals: Dict[str, Any],
    blockchain_history: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Calls Claude as a Senior Neurologist using the blockchain audit trail as
    verified medical history. Returns an empty dict on failure.
    """
    client = _get_client()
    if client is None:
        return {}

    user_content = json.dumps({
        "current_symptoms": symptoms,
        "live_vitals": vitals,
        "blockchain_history": blockchain_history,
    }, ensure_ascii=True)

    try:
        response = client.messages.create(
            model=DEFAULT_MODEL,
            max_tokens=200,
            temperature=0,
            system=_BLOCKCHAIN_DIAGNOSTIC_SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_content}],
        )
        content = "".join(
            block.text for block in response.content if getattr(block, "type", "") == "text"
        ).strip()
        parsed = _safe_json_loads(content)
        required = {"primary_diagnosis", "blockchain_correlation", "mechanism_of_injury", "routing_priority"}
        if required.issubset(parsed):
            return {
                "diagnosis": str(parsed["primary_diagnosis"]),
                "blockchain_correlation": str(parsed["blockchain_correlation"]),
                "mechanism_of_injury": str(parsed["mechanism_of_injury"]),
                "routing_priority": str(parsed["routing_priority"]),
                "diagnosis_severity": min(10, max(1, int(parsed.get("severity", 5)))),
                "required_specialist": str(parsed.get("required_specialist", "general")),
            }
        logger.warning(f"[BLOCKCHAIN DIAGNOSTIC] Missing fields in response: {list(parsed.keys())}")
    except Exception as exc:
        logger.error(f"[BLOCKCHAIN DIAGNOSTIC] Claude call failed: {exc}")

    return {}


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


_SCENE_EXTRACTION_SYSTEM_PROMPT = (
    "You are a senior emergency physician and trauma specialist analyzing a scene photograph. "
    "Extract every clinically relevant detail visible in the image. Be precise and concise. "
    "Output ONLY valid JSON — no markdown, no commentary:\n"
    "{\n"
    '  "severity_estimate": <integer 1-10>,\n'
    '  "mechanism_of_injury": "<string — e.g. high-speed collision, fall, burn>",\n'
    '  "patient_count": <integer — visible victims>,\n'
    '  "consciousness_estimate": "<string — conscious/unconscious/unclear>",\n'
    '  "visible_injuries": ["<specific injury>"],\n'
    '  "blood_loss": {\n'
    '    "present": <true|false>,\n'
    '    "severity": "<none|minor|moderate|significant|severe>",\n'
    '    "description": "<what is visible>"\n'
    '  },\n'
    '  "scene_hazards": ["<hazard>"],\n'
    '  "vehicle_damage_severity": "<none|minor|moderate|severe|destroyed>",\n'
    '  "recommended_resources": ["<resource>"],\n'
    '  "scene_summary": "<2-3 sentence clinical summary for the receiving ER>"\n'
    "}"
)

_SCENE_SAFE_DEFAULT: Dict[str, Any] = {
    "severity_estimate": 0,
    "mechanism_of_injury": "unknown",
    "patient_count": 1,
    "consciousness_estimate": "unclear",
    "visible_injuries": [],
    "blood_loss": {"present": False, "severity": "none", "description": ""},
    "scene_hazards": [],
    "vehicle_damage_severity": "none",
    "recommended_resources": [],
    "scene_summary": "Fallback scene context (Anthropic API key missing or unavailable).",
}


def extract_scene_context(
    image_base64: str,
    media_type: str = "image/jpeg",
) -> Dict[str, Any]:
    """
    Sends a base64-encoded scene image to Claude vision and returns a rich
    structured scene context dict. Always returns _SCENE_SAFE_DEFAULT on any
    failure — callers never need to guard against exceptions.
    """
    if not image_base64:
        return dict(_SCENE_SAFE_DEFAULT)

    client = _get_client()
    if client is None:
        return dict(_SCENE_SAFE_DEFAULT)

    try:
        response = client.messages.create(
            model=DEFAULT_MODEL,
            max_tokens=600,
            temperature=0,
            system=_SCENE_EXTRACTION_SYSTEM_PROMPT,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": media_type,
                                "data": image_base64,
                            },
                        },
                        {
                            "type": "text",
                            "text": (
                                "Analyze this emergency scene photograph. "
                                "Extract all clinically relevant information and output JSON only."
                            ),
                        },
                    ],
                }
            ],
        )
        content = "".join(
            block.text for block in response.content if getattr(block, "type", "") == "text"
        ).strip()
        parsed = _safe_json_loads(content)

        raw_hint = parsed.get("severity_estimate", 0)
        severity = min(10, max(0, int(raw_hint) if str(raw_hint).lstrip("-").isdigit() else 0))

        blood_raw = parsed.get("blood_loss") if isinstance(parsed.get("blood_loss"), dict) else {}

        return {
            "severity_estimate": severity,
            "mechanism_of_injury": str(parsed.get("mechanism_of_injury", "unknown")),
            "patient_count": max(1, int(parsed.get("patient_count", 1) or 1)),
            "consciousness_estimate": str(parsed.get("consciousness_estimate", "unclear")),
            "visible_injuries": [str(i) for i in parsed.get("visible_injuries", []) if i],
            "blood_loss": {
                "present": bool(blood_raw.get("present", False)),
                "severity": str(blood_raw.get("severity", "none")),
                "description": str(blood_raw.get("description", "")),
            },
            "scene_hazards": [str(h) for h in parsed.get("scene_hazards", []) if h],
            "vehicle_damage_severity": str(parsed.get("vehicle_damage_severity", "none")),
            "recommended_resources": [str(r) for r in parsed.get("recommended_resources", []) if r],
            "scene_summary": str(parsed.get("scene_summary", "")),
        }
    except Exception as exc:
        logger.error(f"[SCENE] Image analysis failed (model={DEFAULT_MODEL}): {exc}")
        return dict(_SCENE_SAFE_DEFAULT)


def format_scene_as_diagnostic_context(scene: Dict[str, Any]) -> str:
    """
    Converts a scene_context dict into a compact text block that can be
    injected into the diagnostic agent prompt so Claude reasons about the
    visual evidence alongside the text description.
    """
    if not scene or not scene.get("scene_summary"):
        return ""

    blood = scene.get("blood_loss", {})
    lines = [
        "=== SCENE EVIDENCE (from photograph) ===",
        f"Summary       : {scene.get('scene_summary', '')}",
        f"Mechanism     : {scene.get('mechanism_of_injury', 'unknown')}",
        f"Severity est. : {scene.get('severity_estimate', 0)}/10",
        f"Victims visible: {scene.get('patient_count', 1)}",
        f"Consciousness : {scene.get('consciousness_estimate', 'unclear')}",
        f"Injuries seen : {', '.join(scene.get('visible_injuries', [])) or 'none documented'}",
        f"Blood loss    : {blood.get('severity', 'none')} — {blood.get('description', '')}",
        f"Vehicle damage: {scene.get('vehicle_damage_severity', 'none')}",
        f"Hazards       : {', '.join(scene.get('scene_hazards', [])) or 'none'}",
        f"Resources needed: {', '.join(scene.get('recommended_resources', [])) or 'standard'}",
        "=========================================",
    ]
    return "\n".join(lines)


_FIRST_AID_SYSTEM_PROMPT = (
    "You are an emergency first aid expert writing instructions for a bystander — NOT a medic. "
    "Generate 4-5 clear, actionable steps they should follow RIGHT NOW until the ambulance arrives. "
    "Use plain language. No medical jargon. Each step must be something a layperson can physically do. "
    "Output ONLY compact JSON — no markdown, no extra text:\n"
    '{"steps":[{"title":"short action title (max 6 words)","description":"clear instruction in 1-2 sentences","priority":"critical|high|normal"}]}'
)


def generate_first_aid_steps(
    diagnosis: str,
    urgency: str,
    condition_flags: Dict[str, Any],
    specialist: str,
    advice_action: str,
) -> List[Dict[str, Any]]:
    """
    Calls Claude (Haiku) to produce bystander-facing first aid steps.
    Returns an empty list if the LLM is unavailable or returns invalid JSON.
    """
    client = _get_client()
    if client is None:
        return []

    user_content = json.dumps({
        "diagnosis": diagnosis,
        "urgency": urgency,
        "patient_condition": condition_flags,
        "specialist_needed": specialist,
        "dispatcher_advice": advice_action,
    }, ensure_ascii=True)

    try:
        response = client.messages.create(
            model=FAST_MODEL,
            max_tokens=600,
            temperature=0,
            system=_FIRST_AID_SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_content}],
        )
        content = "".join(
            block.text for block in response.content if getattr(block, "type", "") == "text"
        ).strip()
        parsed = _safe_json_loads(content)
        if "steps" in parsed and isinstance(parsed["steps"], list):
            return [
                {
                    "title": str(s.get("title", "")),
                    "description": str(s.get("description", "")),
                    "priority": str(s.get("priority", "normal")),
                }
                for s in parsed["steps"]
                if s.get("title") and s.get("description")
            ]
        logger.warning(f"[FIRST AID] Unexpected response shape: {list(parsed.keys())}")
    except Exception as exc:
        logger.error(f"[FIRST AID] Claude call failed: {exc}")

    # Deterministic fallback so first-aid is never empty in degraded mode.
    steps: List[Dict[str, Any]] = []
    if not condition_flags.get("conscious", True):
        steps.append({
            "title": "Check responsiveness now",
            "description": "Tap shoulders and call loudly. If no response, keep patient flat and monitor breathing continuously.",
            "priority": "critical",
        })
    if not condition_flags.get("breathing", True):
        steps.append({
            "title": "Open airway",
            "description": "Tilt head slightly back and lift chin to open airway. Start rescue breathing if trained.",
            "priority": "critical",
        })
    if condition_flags.get("bleeding", False):
        steps.append({
            "title": "Control bleeding",
            "description": "Apply firm direct pressure with clean cloth. Do not remove soaked layers; add more over them.",
            "priority": "critical",
        })

    # Neurologic symptom fallback for cases like dizziness+vomiting+can't walk straight.
    if diagnosis.lower().find("stroke") != -1 or diagnosis.lower().find("neurolog") != -1:
        steps.append({
            "title": "Keep patient still",
            "description": "Lay patient on side if vomiting. Keep head slightly elevated. Do not give food, drink, or tablets.",
            "priority": "high",
        })

    steps.append({
        "title": "Monitor and reassure",
        "description": "Stay with the patient, note any worsening signs, and share changes with arriving medical team.",
        "priority": "normal",
    })

    # Keep output compact and predictable.
    deduped: List[Dict[str, Any]] = []
    seen_titles = set()
    for s in steps:
        title = s.get("title", "")
        if title and title not in seen_titles:
            deduped.append(s)
            seen_titles.add(title)
    return deduped[:5]


def generate_batch_explanations(items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Generate pros/cons/explanation for ALL hospitals in a SINGLE Haiku call.
    Returns a list in the same order as items. Falls back to rule-based per item on failure.
    """
    client = _get_client()
    if client is not None and items:
        prompt = (
            "For each hospital in the array, produce a compact summary. "
            "Return a JSON array in the same order with objects containing keys: "
            "pros (array, max 2 items, each under 10 words), "
            "cons (array, max 2 items, each under 10 words), "
            "explanation (one sentence max 20 words). "
            "No markdown. Input: "
            f"{json.dumps(items, ensure_ascii=True)}"
        )
        def _call(model_name: str) -> List[Dict[str, Any]]:
            response = client.messages.create(
                model=model_name,
                max_tokens=500,
                temperature=0,
                messages=[{"role": "user", "content": prompt}],
            )
            content = "".join(
                block.text for block in response.content if getattr(block, "type", "") == "text"
            ).strip()
            return _safe_json_loads_list(content)

        try:
            parsed = _call(FAST_MODEL)
            if len(parsed) == len(items):
                return parsed
            logger.warning(f"[BATCH EXPLANATION] Length mismatch on FAST model: got {len(parsed)}, expected {len(items)}")
        except Exception as exc:
            logger.error(f"[BATCH EXPLANATION] FAST model call failed: {exc}")

        # Retry once on DEFAULT model if fast model output is malformed.
        try:
            parsed = _call(DEFAULT_MODEL)
            if len(parsed) == len(items):
                return parsed
            logger.warning(f"[BATCH EXPLANATION] Length mismatch on DEFAULT model: got {len(parsed)}, expected {len(items)}")
        except Exception as exc:
            logger.error(f"[BATCH EXPLANATION] DEFAULT model retry failed: {exc}")

    return [generate_recommendation_text(item) for item in items]
