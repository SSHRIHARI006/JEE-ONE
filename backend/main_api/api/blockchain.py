import hashlib
import json
import logging
from datetime import datetime, timezone

logger = logging.getLogger('jivan')

# In-memory chain — persists only for the lifetime of the process.
# Each element is a signed block dict.
_chain = []

# Genesis hash: 64 zeros, anchors the first real block
_GENESIS_HASH = "0" * 64


def _latest_hash() -> str:
    """Return the hash of the most recent block, or the genesis hash if empty."""
    if _chain:
        return _chain[-1]["block_hash"]
    return _GENESIS_HASH


def get_patient_blockchain_history(patient_id: str) -> list:
    """
    Return all blockchain blocks associated with a patient.

    Joins the in-memory chain with DB records to build a rich audit trail.
    Each entry includes the original block fields plus clinical context
    (urgency, specialist, events) pulled from EmergencyCases / Triage / EventLogs.
    """
    from .models import EmergencyCases, Triage, EventLogs

    # Collect all case_ids ever created for this patient
    cases = EmergencyCases.objects.filter(patient_id=patient_id).order_by('timestamp')
    case_ids = {c.case_id for c in cases}

    # Index DB records for quick lookup
    case_map = {c.case_id: c for c in cases}
    triage_map = {}
    for t in Triage.objects.filter(case_id__in=case_ids):
        triage_map[t.case_id] = t
    events_map: dict = {}
    for e in EventLogs.objects.filter(case_id__in=case_ids).order_by('timestamp'):
        events_map.setdefault(e.case_id, []).append(e.event_type)

    # Match in-memory chain blocks to this patient's cases
    chain_blocks = {b["case_id"]: b for b in _chain if b["case_id"] in case_ids}

    history = []
    for case in cases:
        cid = case.case_id
        block = chain_blocks.get(cid)
        triage = triage_map.get(cid)
        entry = {
            "case_id": cid,
            "timestamp": case.timestamp.isoformat() if case.timestamp else None,
            "severity": block["severity"] if block else case.severity_score,
            "urgency_level": case.urgency_level,
            "required_specialist": case.required_specialist,
            "location": {"latitude": case.latitude, "longitude": case.longitude},
            "vitals": {"spo2": case.spo2, "systolic_bp": case.systolic_bp},
            "needs_icu": bool(triage.needs_icu) if triage else False,
            "events": events_map.get(cid, []),
        }
        if block:
            entry["block_index"] = block["index"]
            entry["block_hash"] = block["block_hash"]
            entry["hospital_id"] = block["hospital_id"]
        history.append(entry)

    logger.info(f"[JIVAN BLOCKCHAIN] History for {patient_id}: {len(history)} record(s).")
    return history


def sign_decision_block(case_id: str, hospital_id: str, severity: int) -> dict:
    """
    Append a new block to the in-memory chain recording a routing decision.

    Returns a dict with keys:
        index, timestamp, case_id, hospital_id, severity, prev_hash, block_hash
    """
    index = len(_chain)
    timestamp = datetime.now(timezone.utc).isoformat()
    prev_hash = _latest_hash()

    # Build the block without the hash first — used as the hash input
    block_without_hash = {
        "index": index,
        "timestamp": timestamp,
        "case_id": case_id,
        "hospital_id": hospital_id,
        "severity": severity,
        "prev_hash": prev_hash,
    }

    # SHA-256 over a deterministic JSON serialisation
    raw = json.dumps(block_without_hash, sort_keys=True)
    block_hash = hashlib.sha256(raw.encode()).hexdigest()

    block = {**block_without_hash, "block_hash": block_hash}
    _chain.append(block)

    logger.info(f"[JIVAN BLOCKCHAIN] Block #{index} signed. Hash: {block_hash[:16]}...")

    return block
