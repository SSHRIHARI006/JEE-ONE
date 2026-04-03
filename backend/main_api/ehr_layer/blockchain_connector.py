import requests
import json
from datetime import datetime

class BlockchainClient:
    def __init__(self, node_url="http://localhost:3001"):
        self.node_url = node_url

    def log_medical_access(self, patient_id, ambulance_id, doctor_name, description):
        """
        Broadcasts a medical access event to the blockchain network.
        Matches the 'sender, recipient, doctor, date, description' structure of your JS code.
        """
        endpoint = f"{self.node_url}/transaction/broadcast"
        
        payload = {
            "sender": patient_id,        # The Patient (Data Owner)
            "recipient": ambulance_id,   # The Ambulance/Medic (Data Consumer)
            "doctor": doctor_name,       # Assigned AI/Medic Name
            "date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "description": description    # e.g., "Unlocked EHR - Severity 8.5"
        }

        try:
            response = requests.post(endpoint, json=payload)
            return response.json()
        except Exception as e:
            return {"error": str(e)}

    def mine_block(self):
        """Triggers mining on the Node.js node to secure the transactions."""
        try:
            response = requests.get(f"{self.node_url}/mine")
            return response.json()
        except Exception as e:
            return {"error": str(e)}