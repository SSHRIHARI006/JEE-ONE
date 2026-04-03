import requests
import os
from api.models import Hospital

class ORSClient:
    def __init__(self):
        self.api_key = os.getenv('ORS_API_KEY')
        self.url = "https://api.openrouteservice.org/v2/matrix/driving-car"

    def rank_hospitals(self, user_lat, user_lon):
        # 1. Get hospitals from your MySQL JIVAN DB
        hospitals = Hospital.objects.all()
        if not hospitals:
            return "No hospitals in database."

        # 2. Format coordinates for ORS [longitude, latitude]
        locations = [[user_lon, user_lat]] # Source is index 0
        for h in hospitals:
            locations.append([float(h.longitude), float(h.latitude)])

        body = {
            "locations": locations,
            "sources": [0], # Only calculate from the patient
            "destinations": list(range(1, len(locations))), # To all hospitals
            "metrics": ["duration"]
        }

        headers = {
            'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
            'Authorization': self.api_key,
            'Content-Type': 'application/json; charset=utf-8'
        }

        response = requests.post(self.url, json=body, headers=headers)
        
        if response.status_code == 200:
            durations = response.json()['durations'][0] # List of seconds
            results = []
            for i, time_sec in enumerate(durations):
                results.append({
                    "name": hospitals[i].hospital_name,
                    "eta_min": round(time_sec / 60, 2)
                })
            # Sort by fastest ETA
            return sorted(results, key=lambda x: x['eta_min'])
        else:
            return f"Error: {response.json()}"