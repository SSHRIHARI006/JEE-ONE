from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Hospitals
import requests
import os

class HospitalRankerView(APIView):
    def post(self, request):
        # 1. Get User Location from Request
        user_lat = request.data.get('latitude')
        user_lon = request.data.get('longitude')
        
        if not user_lat or not user_lon:
            return Response({"error": "Latitude and Longitude required"}, status=400)

        # 2. Fetch Hospitals from MySQL JIVAN
        hospitals = list(Hospitals.objects.all())
        if not hospitals:
            return Response({"error": "No hospitals found in DB"}, status=404)

        # 3. Prepare ORS Matrix Request
        ors_key = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjMyMGNjOGI4ODc2YTQ4NTI4ZTMzNmYwNGI3NjE0YmNiIiwiaCI6Im11cm11cjY0In0='
        url = "https://api.openrouteservice.org/v2/matrix/driving-car"
        
        # ORS expects [longitude, latitude]
        locations = [[float(user_lon), float(user_lat)]] 
        for h in hospitals:
            locations.append([float(h.longitude), float(h.latitude)])

        body = {
            "locations": locations,
            "sources": [0], # User is index 0
            "destinations": list(range(1, len(locations))), # Everything else
            "metrics": ["duration"]
        }

        headers = {
            'Authorization': ors_key,
            'Content-Type': 'application/json'
        }

        # 4. Call ORS and Rank
        response = requests.post(url, json=body, headers=headers)
        
        if response.status_code == 200:
            # durations[0] is the list of travel times in seconds
            durations = response.json()['durations'][0]
            ranked_list = []
            
            for i, time_sec in enumerate(durations):
                ranked_list.append({
                    "hospital_name": hospitals[i].hospital_name,
                    "eta_minutes": round(time_sec / 60, 2),
                    "hospital_id": hospitals[i].hospital_id
                })

            # Sort by fastest (lowest ETA)
            ranked_list.sort(key=lambda x: x['eta_minutes'])
            return Response({"ranked_hospitals": ranked_list})
        
        return Response({"error": "ORS API Failed", "details": response.json()}, status=500)