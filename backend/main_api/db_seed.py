import mysql.connector
import random
import string
from datetime import datetime, timedelta

# --- CONFIG ---
DB_CONFIG = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': 'iiitnBX248',
    'database': 'JIVAN'
}

def uid(p):
    return p + "_" + ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))

def dist(lat1, lon1, lat2, lon2):
    return ((lat1 - lat2)**2 + (lon1 - lon2)**2)**0.5 * 111

# --- CONNECT ---
conn = mysql.connector.connect(**DB_CONFIG)
cursor = conn.cursor()

# ------------------ 1. HOSPITALS ------------------
hospitals_data = [
    ("Sahyadri Kothrud", 18.5088, 73.8185),
    ("Krishna Hospital", 18.5072, 73.8210),
    ("Deoyani Hospital", 18.5015, 73.8205),
    ("Mai Mangeshkar", 18.4875, 73.8050),
    ("Cloudnine Kothrud", 18.5065, 73.8120),
    ("Ruby Hall", 18.5334, 73.8772),
    ("Sassoon General", 18.5265, 73.8765)
]

hospital_ids = []

for name, lat, lon in hospitals_data:
    hid = uid("hosp")
    hospital_ids.append((hid, lat, lon))

    cursor.execute("""
        INSERT INTO hospitals (hospital_id, hospital_name, latitude, longitude, hospital_type, has_icu, max_icu_beds)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (hid, name, lat, lon, 'Private', 1, random.randint(20, 50)))

    cursor.execute("""
        INSERT INTO hospital_dynamic_status (hospital_id, available_icu_beds, current_load_percentage, avg_intake_delay, readiness_score, last_updated_timestamp)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (hid, random.randint(0, 10), random.uniform(30, 90),
          random.randint(2, 15), random.uniform(0.5, 0.9), datetime.now()))

# ------------------ 2. AMBULANCES ------------------
ambulances = []
for _ in range(10):
    aid = uid("amb")
    lat = 18.51 + random.uniform(-0.02, 0.02)
    lon = 73.81 + random.uniform(-0.02, 0.02)

    cursor.execute("""
        INSERT INTO ambulances (ambulance_id, latitude, longitude, status, last_updated_timestamp)
        VALUES (%s, %s, %s, %s, %s)
    """, (aid, lat, lon, 'available', datetime.now()))

    ambulances.append((aid, lat, lon))

# ------------------ 3. CASE GENERATION ------------------
scenarios = [("cardiac", "cardio"), ("stroke", "neuro"), ("accident", "trauma")]

for _ in range(50):

    cid = uid("case")
    pid = uid("pat")

    lat = 18.518 + random.uniform(-0.01, 0.01)
    lon = 73.815 + random.uniform(-0.01, 0.01)

    # --- PATIENT ---
    cursor.execute("""
        INSERT INTO patients (patient_id, age, gender, created_at)
        VALUES (%s, %s, %s, %s)
    """, (pid, random.randint(18, 80), random.choice(['male', 'female']), datetime.now()))

    # --- VITALS ---
    spo2 = random.randint(85, 99)
    sbp = random.randint(100, 180)

    severity = 5
    if spo2 < 90: severity += 2
    if sbp > 160: severity += 2

    urgency = 'critical' if severity > 7 else 'high'
    specialist = random.choice(scenarios)[1]
    needs_icu = 1 if severity >= 8 else 0

    # --- CASE ---
    cursor.execute("""
        INSERT INTO emergency_cases (case_id, patient_id, source_type, timestamp, latitude, longitude, spo2, systolic_bp, severity_score, urgency_level, required_specialist)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (cid, pid, 'ambulance',
          datetime.now() - timedelta(hours=random.randint(0, 24)),
          lat, lon, spo2, sbp, severity, urgency, specialist))

    # ---------------- TRIAGE ----------------
    cursor.execute("""
        INSERT INTO triage (case_id, severity_score, urgency_level, needs_icu, required_specialist)
        VALUES (%s, %s, %s, %s, %s)
    """, (cid, severity, urgency, needs_icu, specialist))

    # ---------------- RECOMMENDATIONS ----------------
    recs = []

    for hid, hlat, hlon in hospital_ids:
        d = dist(lat, lon, hlat, hlon)
        eta = int(d / 40 * 60)

        score = eta + random.uniform(10, 50)
        comp = "good" if score < 60 else "average"

        recs.append((hid, eta, score, comp))

    recs.sort(key=lambda x: x[2])

    for r in recs[:3]:
        cursor.execute("""
            INSERT INTO recommendations (case_id, hospital_id, eta, score, compatibility)
            VALUES (%s, %s, %s, %s, %s)
        """, (cid, r[0], r[1], r[2], r[3]))

    best = recs[0]

    # ---------------- AMBULANCE ASSIGNMENT ----------------
    amb = min(ambulances, key=lambda x: dist(x[1], x[2], lat, lon))
    eta_patient = int(dist(amb[1], amb[2], lat, lon) / 40 * 60)

    cursor.execute("""
        INSERT INTO ambulance_assignment (case_id, ambulance_id, eta_to_patient)
        VALUES (%s, %s, %s)
    """, (cid, amb[0], eta_patient))

    # ---------------- EVENT LOGS ----------------
    events = ["CREATED", "TRIAGED", "RECOMMENDED", "ASSIGNED"]

    for e in events:
        cursor.execute("""
            INSERT INTO event_logs (event_id, case_id, event_type, timestamp)
            VALUES (%s, %s, %s, %s)
        """, (uid("ev"), cid, e, datetime.now()))

# ------------------ DONE ------------------
conn.commit()
cursor.close()
conn.close()

print("JIVAN HYBRID DATABASE SEEDED SUCCESSFULLY 🚀")