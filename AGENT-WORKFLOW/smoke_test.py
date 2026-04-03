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


sample_emergency = "patient unconscious, chest pain, not breathing"
sample_advice = "mild headache and cough"

patient_data = run_input_agent(sample_emergency)
patient = PatientEmergencyModel(**patient_data)
triage_context = run_triage_agent(patient)
triage_eval = evaluate_triage(patient, triage_context)
decision = route_decision(patient.case_id, triage_eval["severity_score"])
recommendations = recommend_hospitals(patient.case_id, patient.location, triage_eval["requirements"], top_n=3)
recommendations.recommendations = run_explanation_agent(recommendations.recommendations)
ambulance = assign_ambulance(patient.case_id, patient.location)

top_hospital_id = recommendations.recommendations[0].hospital_id
hospital_coords = load_hospital_coordinates(top_hospital_id)
hospital_dest = (
    CoordinatesModel(latitude=hospital_coords["latitude"], longitude=hospital_coords["longitude"])
    if hospital_coords
    else patient.location
)
route = build_route(patient.case_id, patient.location, top_hospital_id, hospital_dest)

public_result = handle_public_request(sample_emergency)
medic_result = handle_medic_request(sample_emergency)
advice_result = handle_public_request(sample_advice)

assert patient_data["case_id"]
assert isinstance(patient_data["symptoms"], list)
assert patient.condition_flags is not None
assert isinstance(triage_context, dict)
assert triage_eval["severity_score"] >= 0
assert decision.decision_type in {"advice", "hospital_suggestion", "emergency_routing"}
assert len(recommendations.recommendations) >= 1
assert recommendations.recommendations[0].explanation
assert route.destination_hospital_id
assert public_result["decision_type"] in {"advice", "hospital_suggestion", "emergency_routing"}
assert medic_result["selected_hospital_id"] is not None
assert advice_result["decision_type"] == "advice"

print("SMOKE_TEST_OK")
print("CASE_ID", patient.case_id)
print("SEVERITY", triage_eval["severity_score"])
print("DECISION", decision.decision_type)
print("RECOMMENDATIONS", len(recommendations.recommendations))
for i, rec in enumerate(recommendations.recommendations, 1):
    print(f"  [{i}] {rec.hospital_name} | ETA {rec.eta}min | dist {rec.distance_km}km | {rec.compatibility} | risk: {rec.risk_flags}")
    print(f"      pros: {rec.pros}")
    print(f"      cons: {rec.cons}")
    print(f"      explanation: {rec.explanation}")
print("AMBULANCE", ambulance.model_dump() if ambulance else None)
print("ROUTE", route.model_dump())
print("PUBLIC decision:", public_result["decision_type"])
print("PUBLIC case_summary:", public_result.get("case_summary"))
print("PUBLIC advice:", public_result.get("advice"))
print("PUBLIC risk_summary:", public_result.get("risk_summary"))
print("PUBLIC events:", public_result.get("events"))
print("MEDIC hospital:", medic_result.get("selected_hospital"))
print("MEDIC route:", medic_result.get("route"))
print("ADVICE decision:", advice_result["decision_type"])
print("ADVICE advice:", advice_result["advice"])
