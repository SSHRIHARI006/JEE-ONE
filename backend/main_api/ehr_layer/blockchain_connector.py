# main_api/ehr_layer/blockchain_connector.py
import requests

BLOCKCHAIN_NODE = "http://localhost:3001"

def log_medical_access(patient_id, ambulance_id, action):
    payload = {
        "sender": patient_id,
        "recipient": f"AMB_{ambulance_id}",
        "doctor": "SYSTEM_AI",
        "date": "2026-04-03",
        "description": f"ACCESS_GRANTED: {action}"
    }
    requests.post(f"{BLOCKCHAIN_NODE}/transaction/broadcast", json=payload)