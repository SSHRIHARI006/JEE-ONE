"""
Encodes an image and writes a complete postman_body.json ready to paste into Postman.

Usage:
    python make_postman_body.py <path_to_image>

Example:
    python make_postman_body.py C:\Users\mohap\Desktop\accident.jpg
"""

import base64
import json
import mimetypes
import sys
from pathlib import Path

if len(sys.argv) < 2:
    print("Usage: python make_postman_body.py <path_to_image>")
    sys.exit(1)

image_path = Path(sys.argv[1])
if not image_path.exists():
    print(f"[ERROR] File not found: {image_path}")
    sys.exit(1)

mime, _ = mimetypes.guess_type(str(image_path))
media_type = mime or "image/jpeg"

with open(image_path, "rb") as f:
    b64 = base64.b64encode(f.read()).decode("utf-8")

body = {
    "patient_id": "PATIENT-882",
    "input_text": (
        "Severe road accident. Multiple vehicles involved. "
        "One person lying on road, unresponsive. Visible head injury and bleeding. "
        "Bystanders present. Needs immediate emergency response."
    ),
    "source_type": "public",
    "vitals": {
        "spo2": 91,
        "systolic_bp": 85,
        "diastolic_bp": 50
    },
    "location": {
        "latitude": 18.518,
        "longitude": 73.815
    },
    "image_base64": b64
}

out_path = Path(__file__).parent / "postman_body.json"
with open(out_path, "w") as f:
    json.dump(body, f, indent=2)

size_kb = len(b64) // 1024
print(f"[OK] Image encoded  : {image_path.name}  ({size_kb} KB base64)")
print(f"[OK] Media type     : {media_type}")
print(f"[OK] Body written to: {out_path}")
print()
print("─" * 55)
print("  Postman setup:")
print("─" * 55)
print("  Method  : POST")
print("  URL     : http://127.0.0.1:8000/api/sos/")
print("  Headers : Content-Type: application/json")
print("  Body    : raw → JSON  →  paste contents of postman_body.json")
print("─" * 55)
print()
print("  Or use Body > raw and open the file:")
print(f"  {out_path}")
