import json
from datetime import datetime
from logic.agents.decision_router import route_decision
from logic.agents.explanation_agent import run_explanation_agent
from logic.agents.input_agent import run_input_agent
from logic.agents.triage_agent import run_triage_agent
from logic.models.patient_model import CoordinatesModel, PatientEmergencyModel
from logic.services.ambulance_service import assign_ambulance
from logic.services.hospital_service import recommend_hospitals
from logic.services.routing_service import build_route
from logic.services.triage_service import evaluate_triage
from logic.utils.db_store import load_hospital_coordinates
from logic.views.medic_view import handle_medic_request
from logic.views.public_view import handle_public_request

# --- PUNE COORDINATES (MIT-WPU Area) ---
# Previous version was using Bangalore (12.93, 77.61), causing huge ETAs.
PUNE_LAT = 18.518
PUNE_LON = 73.815

def run_test_scenario(description, name):
    print(f"\n{'='*20} TESTING SCENARIO: {name} {'='*20}")
    
    # 1. Input Agent (Parse natural language)
    patient_data = run_input_agent(description)
    # Manually override coordinates to Pune for this local test
    patient_data["location"] = {"latitude": PUNE_LAT, "longitude": PUNE_LON}
    
    patient = PatientEmergencyModel(**patient_data)
    
    # 2. Triage & Evaluation
    triage_context = run_triage_agent(patient)
    triage_eval = evaluate_triage(patient, triage_context)
    
    # 3. Decision Routing (Emergency vs Advice)
    decision = route_decision(patient.case_id, triage_eval["severity_score"])
    
    print(f"CASE_ID: {patient.case_id}")
    print(f"SEVERITY: {triage_eval['severity_score']} | DECISION: {decision.decision_type}")

    if decision.decision_type != "advice":
        # 4. Hospital Recommendation
        recommendations = recommend_hospitals(patient.case_id, patient.location, triage_eval["requirements"], top_n=3)
        recommendations.recommendations = run_explanation_agent(recommendations.recommendations)
        
        # 5. Ambulance & Route
        ambulance = assign_ambulance(patient.case_id, patient.location)
        top_hospital = recommendations.recommendations[0]
        hospital_coords = load_hospital_coordinates(top_hospital.hospital_id)
        
        dest = CoordinatesModel(latitude=hospital_coords["latitude"], longitude=hospital_coords["longitude"])
        route = build_route(patient.case_id, patient.location, top_hospital.hospital_id, dest)

        # Output Results
        for i, rec in enumerate(recommendations.recommendations, 1):
            print(f"  [{i}] {rec.hospital_name} | ETA: {rec.eta} min | Dist: {rec.distance_km:.2f} km")
            print(f"      Reasoning: {rec.explanation}")
        
        print(f"AMBULANCE: {ambulance.ambulance_id} | Status: {ambulance.status}")
        print(f"ROUTE: {route.route_metrics.traffic_level} traffic | ETA: {route.route_metrics.estimated_travel_time} min")
    else:
        print("SYSTEM ADVICE: Non-critical case. Suggesting home care.")

# --- RUNNING TESTS ---

# Test 1: The Critical Scenario (Should trigger Emergency Routing)
run_test_scenario("Patient unconscious, chest pain, difficulty breathing", "CRITICAL SOS")

# Test 2: The Non-Critical Scenario (Should trigger Advice)
run_test_scenario("I have a mild scratch on my finger and a slight cough", "MINOR INJURY")

print("\nSMOKE_TEST_COMPLETE 🚀")