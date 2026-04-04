"""Quick debug script to find the exact pipeline failure."""
import os, sys, traceback

# Add AGENT-WORKFLOW to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Add Django project to path
django_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'backend', 'main_api')
sys.path.insert(0, os.path.abspath(django_path))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'main_api.settings')

try:
    import django
    django.setup()
    print("OK: Django setup complete")
except Exception as e:
    print(f"Django setup failed (this is OK for raw pipeline test): {e}")

print("\n=== Step 1: Testing Claude client ===")
try:
    from logic.utils.claude_client import _get_client
    client = _get_client()
    print(f"Claude client: {'AVAILABLE' if client else 'MISSING (will use heuristics)'}")
except Exception as e:
    print(f"FAIL: {e}")
    traceback.print_exc()

print("\n=== Step 2: Testing input agent ===")
try:
    from logic.agents.input_agent import run_input_agent
    data = run_input_agent("Accident emergency, patient is conscious and breathing")
    print(f"OK: input agent returned case_id={data.get('case_id')}")
except Exception as e:
    print(f"FAIL input_agent: {e}")
    traceback.print_exc()

print("\n=== Step 3: Testing patient model ===")
try:
    from logic.models.patient_model import PatientEmergencyModel
    data.pop("scene_context", None)
    patient = PatientEmergencyModel(**data)
    print(f"OK: patient model created, case_id={patient.case_id}")
except Exception as e:
    print(f"FAIL patient model: {e}")
    traceback.print_exc()

print("\n=== Step 4: Testing DB connection ===")
try:
    from logic.utils.db_store import get_connection
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT 1")
    cursor.fetchone()
    cursor.close()
    conn.close()
    print("OK: MySQL connection works")
except Exception as e:
    print(f"FAIL MySQL: {e}")
    traceback.print_exc()

print("\n=== Step 5: Testing persist_new_case ===")
try:
    from logic.utils.db_store import persist_new_case
    persist_new_case(patient)
    print("OK: persist_new_case succeeded")
except Exception as e:
    print(f"FAIL persist: {e}")
    traceback.print_exc()

print("\n=== Step 6: Testing triage agent ===")
try:
    from logic.agents.triage_agent import run_triage_agent
    triage_ctx = run_triage_agent(patient)
    print(f"OK: triage context keys = {list(triage_ctx.keys())}")
except Exception as e:
    print(f"FAIL triage: {e}")
    traceback.print_exc()

print("\n=== Step 7: Testing triage evaluation ===")
try:
    from logic.services.triage_service import evaluate_triage
    triage_eval = evaluate_triage(patient, triage_ctx)
    print(f"OK: severity={triage_eval['severity_score']}")
except Exception as e:
    print(f"FAIL triage eval: {e}")
    traceback.print_exc()

print("\n=== Step 8: Testing hospital load ===")
try:
    from logic.utils.db_store import load_hospitals_with_status
    rows = load_hospitals_with_status()
    print(f"OK: {len(rows)} hospitals loaded from DB")
    if rows:
        print(f"  First hospital columns: {list(rows[0].keys())}")
except Exception as e:
    print(f"FAIL hospital load: {e}")
    traceback.print_exc()

print("\n=== Step 9: Testing hospital recommendation ===")
try:
    from logic.services.hospital_service import recommend_hospitals
    recs = recommend_hospitals(
        case_id=patient.case_id,
        patient_location=patient.location,
        requirements=triage_eval["requirements"],
        top_n=3,
    )
    print(f"OK: {len(recs.recommendations)} hospitals recommended")
    for r in recs.recommendations:
        print(f"  {r.hospital_name} — ETA {r.eta}m, score {r.score}")
except Exception as e:
    print(f"FAIL hospital recommendation: {e}")
    traceback.print_exc()

print("\n=== Step 10: Testing explanation agent ===")
try:
    from logic.agents.explanation_agent import run_explanation_agent
    recs.recommendations = run_explanation_agent(recs.recommendations)
    print(f"OK: explanations generated")
except Exception as e:
    print(f"FAIL explanation: {e}")
    traceback.print_exc()

print("\n=== Step 11: Testing decision router ===")
try:
    from logic.agents.decision_router import route_decision
    decision = route_decision(case_id=patient.case_id, severity_score=triage_eval["severity_score"])
    print(f"OK: decision_type={decision.decision_type}")
except Exception as e:
    print(f"FAIL decision: {e}")
    traceback.print_exc()

print("\n=== Step 12: Testing persist_core_outputs ===")
try:
    from logic.utils.db_store import persist_core_outputs
    persist_core_outputs(
        case_id=patient.case_id,
        severity=triage_eval["severity_score"],
        urgency=patient.triage_output.urgency_level,
        needs_icu=triage_eval["requirements"]["ICU"],
        specialist=triage_eval["requirements"]["specialist"],
        recommendations=recs,
        ambulance_assignment=None,
        events=["CASE_CREATED", "TRIAGED"],
    )
    print("OK: persist_core_outputs succeeded")
except Exception as e:
    print(f"FAIL persist_core_outputs: {e}")
    traceback.print_exc()

print("\n=== Step 13: Testing full pipeline ===")
try:
    from logic.views.public_view import handle_public_request
    result = handle_public_request("Accident emergency, patient is conscious and breathing")
    is_fallback = result.get("fallback", False)
    print(f"Pipeline result: fallback={is_fallback}")
    if not is_fallback:
        print(f"  case_id={result.get('case_id')}")
        print(f"  severity={result.get('triage', {}).get('severity')}")
        print(f"  decision_type={result.get('decision_type')}")
        print(f"  first_aid steps={len(result.get('first_aid', []))}")
    else:
        print(f"  message={result.get('message')}")
except Exception as e:
    print(f"FAIL full pipeline: {e}")
    traceback.print_exc()

print("\n=== DONE ===")
