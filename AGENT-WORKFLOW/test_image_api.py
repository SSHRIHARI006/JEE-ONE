"""
Image-informed SOS API test.

Usage:
    python test_image_api.py --image <path_to_image>

If --image is omitted the script runs text-only (baseline comparison).
The Django server must be running at http://127.0.0.1:8000.
"""

import argparse
import base64
import json
import sys
import time
import mimetypes

try:
    import requests
except ImportError:
    print("[ERROR] requests not installed. Run: pip install requests")
    sys.exit(1)

BASE_URL = "http://127.0.0.1:8000"
ENDPOINT = f"{BASE_URL}/api/sos/"

PATIENT_ID   = "PATIENT-882"
INPUT_TEXT   = (
    "Severe road accident. Multiple vehicles involved. "
    "One person lying on road, unresponsive. Visible head injury and bleeding. "
    "Bystanders present. Needs immediate emergency response."
)
VITALS = {
    "spo2": 91,
    "systolic_bp": 85,
    "diastolic_bp": 50,
}
LOCATION = {
    "latitude": 18.518,
    "longitude": 73.815,
}


def encode_image(path: str) -> tuple[str, str]:
    """Return (base64_string, media_type)."""
    mime, _ = mimetypes.guess_type(path)
    media_type = mime or "image/jpeg"
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8"), media_type


def post_sos(payload: dict) -> dict:
    resp = requests.post(
        ENDPOINT,
        json=payload,
        headers={"Content-Type": "application/json"},
        timeout=120,
    )
    resp.raise_for_status()
    return resp.json()


def print_result(result: dict, label: str) -> None:
    print(f"\n{'=' * 60}")
    print(f"  {label}")
    print(f"{'=' * 60}")

    if result.get("fallback"):
        print("[FALLBACK] Agent pipeline failed — Haversine fallback returned.")
        print(f"  Message : {result.get('message')}")
        return

    triage = result.get("triage") or {}
    diag   = result.get("diagnosis") or {}
    adv    = result.get("advice") or {}
    amb    = result.get("ambulance") or {}
    scene  = result.get("scene_context")

    print(f"  Case ID  : {result.get('case_id')}")
    print(f"  Severity : {triage.get('severity')}  |  Urgency: {triage.get('urgency')}")
    print(f"  ICU      : {triage.get('needs_ICU')}  |  Specialist: {triage.get('specialist')}")
    print(f"  Critical : {triage.get('time_to_critical_minutes')} min")

    if diag.get("probable"):
        print(f"\n  Diagnosis: {diag['probable']}")
        print(f"  Reason   : {diag.get('reasoning', '')}")

    if adv.get("message"):
        print(f"\n  Advice   : {adv['message']}")
    if adv.get("action"):
        print(f"  Action   : {adv['action']}")

    if amb:
        print(f"\n  Ambulance: {amb.get('id')} — ETA {amb.get('eta_to_patient')} min  [{amb.get('status')}]")

    routing = result.get("routing") or {}
    if routing.get("name"):
        print(f"\n  Hospital : {routing['name']}  (ETA {routing.get('eta')} min, {routing.get('distance_km')} km)")
        print(f"  Score    : {routing.get('score')}  |  Compat: {routing.get('compatibility')}")

    first_aid = result.get("first_aid") or []
    if first_aid:
        print(f"\n  First Aid ({len(first_aid)} steps):")
        for i, step in enumerate(first_aid, 1):
            print(f"    {i}. [{step.get('priority','?').upper()}] {step.get('title')}")
            print(f"       {step.get('description')}")

    if scene:
        print(f"\n  *** SCENE ANALYSIS APPLIED ***")
        print(f"  Severity hint : {scene.get('severity_hint')}")
        print(f"  Description   : {scene.get('description')}")
        print(f"  Risk indicators: {', '.join(scene.get('risk_indicators', []))}")
        print(f"  Conditions    : {', '.join(scene.get('possible_conditions', []))}")
        print(f"  Note          : {scene.get('note')}")
    else:
        print("\n  [No scene context — image not provided or not influential]")

    print(f"\n  Events: {' → '.join(result.get('events', []))}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Test image-informed SOS API")
    parser.add_argument("--image", help="Path to accident scene image file")
    parser.add_argument("--text-only", action="store_true", help="Skip image, run text-only baseline")
    args = parser.parse_args()

    # ── Baseline: text + vitals only ──────────────────────────────────────────
    base_payload = {
        "patient_id": PATIENT_ID,
        "input_text": INPUT_TEXT,
        "source_type": "public",
        "vitals": VITALS,
        "location": LOCATION,
    }

    print("\n[1/2] Sending TEXT-ONLY request (baseline)...")
    t0 = time.time()
    try:
        result_text = post_sos(base_payload)
        print(f"      Done in {time.time() - t0:.1f}s")
        print_result(result_text, "TEXT-ONLY RESULT")
    except Exception as e:
        print(f"[ERROR] Text-only request failed: {e}")
        result_text = None

    if args.text_only or not args.image:
        print("\n[INFO] Pass --image <path> to also test with scene image.\n")
        return

    # ── Image-informed: text + vitals + base64 image ──────────────────────────
    print(f"\n[2/2] Encoding image: {args.image}")
    try:
        b64, media_type = encode_image(args.image)
    except FileNotFoundError:
        print(f"[ERROR] Image not found: {args.image}")
        sys.exit(1)

    print(f"      Media type : {media_type}")
    print(f"      Size       : {len(b64) // 1024} KB (base64)")

    image_payload = {**base_payload, "image_base64": b64}

    print("\n      Sending IMAGE-INFORMED request...")
    t0 = time.time()
    try:
        result_image = post_sos(image_payload)
        print(f"      Done in {time.time() - t0:.1f}s")
        print_result(result_image, "IMAGE-INFORMED RESULT")
    except Exception as e:
        print(f"[ERROR] Image request failed: {e}")
        return

    # ── Delta summary ──────────────────────────────────────────────────────────
    if result_text and not result_text.get("fallback") and not result_image.get("fallback"):
        sev_text  = (result_text.get("triage") or {}).get("severity", 0)
        sev_image = (result_image.get("triage") or {}).get("severity", 0)
        print(f"\n{'=' * 60}")
        print(f"  DELTA SUMMARY")
        print(f"{'=' * 60}")
        print(f"  Severity   text-only={sev_text}  image-informed={sev_image}  Δ={sev_image - sev_text:+d}")
        applied = (result_image.get("scene_context") or {}).get("applied", False)
        print(f"  Scene influence applied: {applied}")
        if sev_image > sev_text:
            print("  ✓ Scene raised severity as expected for visible trauma.")
        elif sev_image == sev_text:
            print("  ~ Severity unchanged (text description already captured full severity).")


if __name__ == "__main__":
    main()
