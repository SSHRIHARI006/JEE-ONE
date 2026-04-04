"""
Tests /api/analyze-scene/ and then /api/sos/ with the extracted scene context.
Usage:  python test_scene.py <image_path> [base_url]
"""
import base64, json, mimetypes, sys
from pathlib import Path
import requests

BASE = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8000"

if len(sys.argv) < 2:
    print("Usage: python test_scene.py <path_to_image>")
    sys.exit(1)

img = Path(sys.argv[1])
if not img.exists():
    print(f"File not found: {img}"); sys.exit(1)

raw_bytes = img.read_bytes()
mime = "image/jpeg"
if raw_bytes.startswith(b'\x89PNG'):
    mime = "image/png"
elif raw_bytes[8:12] == b'WEBP':
    mime = "image/webp"
elif raw_bytes.startswith(b'GIF8'):
    mime = "image/gif"
    
b64  = base64.b64encode(raw_bytes).decode()
print(f"Image : {img.name}  ({len(b64)//1024} KB base64)  [{mime}]")
print(f"Base  : {BASE}")

# ── Step 1: analyze-scene ─────────────────────────────────────────────────────
print("\n[1/2] POST /api/analyze-scene/ ...")
r = requests.post(f"{BASE}/api/analyze-scene/",
                  json={"image_base64": b64, "media_type": mime},
                  headers={"Content-Type": "application/json"}, timeout=60)
print(f"      Status: {r.status_code}")
print(f"      Body  : {r.text[:300]}")

if r.status_code != 200:
    print("\n[FAIL] analyze-scene returned error. Stopping."); sys.exit(1)

scene = r.json()
scene_summary = str(scene.get("scene_summary", ""))
if "Fallback scene context (Anthropic API key missing or unavailable)." in scene_summary:
    print("\n[WARN] analyze-scene returned fallback context.")
    print("       This usually means the server on this port is running without Anthropic SDK/key.")
    print("       Try running against your venv-backed server, e.g.:")
    print("       python test_scene.py \"C:/Users/mohap/Downloads/accident_test.png\" http://127.0.0.1:8001")

out = Path(__file__).parent / "scene_context.json"
out.write_text(json.dumps(scene, indent=2))
print(f"\n Scene context saved → {out}")
print(json.dumps(scene, indent=2))

# ── Step 2: sos with scene context ────────────────────────────────────────────
print("\n[2/2] POST /api/sos/ with scene_context ...")
r2 = requests.post(f"{BASE}/api/sos/", timeout=120,
    headers={"Content-Type": "application/json"},
    json={
        "patient_id": "PATIENT-882",
        "input_text": "Road accident, person unresponsive on the ground, visible injuries",
        "source_type": "public",
        "vitals": {"spo2": 91, "systolic_bp": 85, "diastolic_bp": 50},
        "location": {"latitude": 18.518, "longitude": 73.815},
        "scene_context": scene,
    })
print(f"      Status: {r2.status_code}")

if r2.status_code == 200:
    d = r2.json()
    if d.get("fallback"):
        print(f"[FALLBACK] {d.get('message')}")
    else:
        t = d.get("triage", {})
        print(f"\n  Severity   : {t.get('severity')}  Urgency: {t.get('urgency')}")
        print(f"  ICU        : {t.get('needs_ICU')}  Specialist: {t.get('specialist')}")
        diag = d.get("diagnosis") or {}
        print(f"  Diagnosis  : {diag.get('probable', 'n/a')}")
        sc = d.get("scene_context")
        print(f"  Scene used : {bool(sc and sc.get('applied'))}")
        print(f"  Events     : {d.get('events')}")
        fa = d.get("first_aid", [])
        if fa:
            print(f"\n  First Aid ({len(fa)} steps):")
            for i, s in enumerate(fa, 1):
                print(f"    {i}. [{s.get('priority','?').upper()}] {s.get('title')}")
