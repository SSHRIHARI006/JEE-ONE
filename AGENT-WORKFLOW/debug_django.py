"""Test the pipeline FROM Django context — matches how Django actually calls it."""
import os, sys, traceback

# Simulate being inside Django — same CWD as `python manage.py runserver`
django_base = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend', 'main_api'))
sys.path.insert(0, django_base)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'jivan_config.settings')

import django
django.setup()

print("=== Django setup OK ===")

# Now import and test exactly like views.py does
print("\n--- Testing workflow_wrapper import ---")
try:
    from api.workflow_wrapper import run_workflow, run_patient_workflow
    print("OK: workflow_wrapper imported")
except Exception as e:
    print(f"FAIL: {e}")
    traceback.print_exc()
    sys.exit(1)

print("\n--- Testing run_workflow (anonymous) ---")
try:
    result = run_workflow("Accident emergency. Patient is conscious. Severity: Critical.", "public")
    print(f"fallback={result.get('fallback', False)}")
    if result.get('fallback'):
        print(f"  message: {result.get('message')}")
    else:
        print(f"  case_id: {result.get('case_id')}")
        print(f"  triage: {result.get('triage')}")
        print(f"  decision_type: {result.get('decision_type')}")
        print(f"  first_aid: {len(result.get('first_aid', []))} steps")
except Exception as e:
    print(f"EXCEPTION: {e}")
    traceback.print_exc()

print("\n--- Testing run_patient_workflow (with patient_id) ---")
try:
    result2 = run_patient_workflow(
        patient_id="TEST-DEBUG-001",
        input_text="Accident emergency. Patient is conscious. Severity: Critical.",
        vitals={"spo2": 94, "systolic_bp": 120, "diastolic_bp": 80},
        source_type="public",
        latitude=18.521,
        longitude=73.812,
    )
    print(f"fallback={result2.get('fallback', False)}")
    if result2.get('fallback'):
        print(f"  message: {result2.get('message')}")
    else:
        print(f"  case_id: {result2.get('case_id')}")
        print(f"  triage: {result2.get('triage')}")
        print(f"  decision_type: {result2.get('decision_type')}")
        print(f"  first_aid: {len(result2.get('first_aid', []))} steps")
except Exception as e:
    print(f"EXCEPTION: {e}")
    traceback.print_exc()

print("\n=== DONE ===")
