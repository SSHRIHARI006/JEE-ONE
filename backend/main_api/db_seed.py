import mysql.connector
import random
import string
import json
from datetime import datetime, timedelta

# --- CONFIG ---
DB_CONFIG = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': 'iiitnBX248', # Change to iiitnBX248
    'database': 'JIVAN'
}

def uid(p):
    return p + "_" + ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))

def dist(lat1, lon1, lat2, lon2):
    return ((lat1 - lat2)**2 + (lon1 - lon2)**2)**0.5 * 111

# --- CONNECT ---
conn = mysql.connector.connect(**DB_CONFIG)
cursor = conn.cursor()

# --- 1. SEED HOSPITALS (Kothrud/Pune Area) ---
# Coordinates centered around MIT-WPU (18.518, 73.815)
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
    hospital_ids.append(hid)
    
    # Static Data (Hospitals table)
    cursor.execute("""
        INSERT INTO hospitals (hospital_id, hospital_name, latitude, longitude, hospital_type, has_ICU, max_ICU_beds)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (hid, name, lat, lon, 'Private', 1, random.randint(20, 50)))

    # Dynamic Data (HospitalDynamicStatus table)
    cursor.execute("""
        INSERT INTO hospital_dynamic_status (hospital_id, available_ICU_beds, current_load_percentage, avg_intake_delay, readiness_score, last_updated_timestamp)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (hid, random.randint(0, 10), random.uniform(30, 90), random.randint(2, 15), random.uniform(0.5, 0.9), datetime.now()))

# --- 2. SEED AMBULANCES ---
for i in range(10):
    aid = uid("amb")
    cursor.execute("""
        INSERT INTO ambulances (ambulance_id, latitude, longitude, status, last_updated_timestamp)
        VALUES (%s, %s, %s, %s, %s)
    """, (aid, 18.51 + random.uniform(-0.02, 0.02), 73.81 + random.uniform(-0.02, 0.02), 'available', datetime.now()))

# --- 3. GENERATE EMERGENCY CASES (Last 24 Hours) ---
scenarios = [("cardiac", "cardio"), ("stroke", "neuro"), ("accident", "trauma")]

for _ in range(50):
    cid = uid("case")
    pid = uid("pat")
    
    # Patient
    cursor.execute("INSERT INTO patients (patient_id, age, gender, created_at) VALUES (%s, %s, %s, %s)",
                   (pid, random.randint(18, 80), random.choice(['male', 'female']), datetime.now()))
    
    # Random Vitals
    spo2 = random.randint(85, 99)
    sbp = random.randint(100, 180)
    sev = 5 + (2 if spo2 < 90 else 0) + (2 if sbp > 160 else 0)
    
    # Case
    cursor.execute("""
        INSERT INTO emergency_cases (case_id, patient_id, source_type, timestamp, latitude, longitude, 
        spo2, systolic_bp, severity_score, urgency_level, required_specialist)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (cid, pid, 'ambulance', datetime.now() - timedelta(hours=random.randint(0, 24)), 
          18.518 + random.uniform(-0.01, 0.01), 73.815 + random.uniform(-0.01, 0.01),
          spo2, sbp, sev, 'critical' if sev > 7 else 'high', random.choice(scenarios)[1]))

conn.commit()
cursor.close()
conn.close()
print("JIVAN Database Seeded Successfully for MIT-WPU/Pune Area!")