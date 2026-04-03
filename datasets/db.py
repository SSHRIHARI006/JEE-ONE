import sqlite3, random, string, json, math, datetime

def uid(p):
    return p + "_" + ''.join(random.choices(string.ascii_lowercase+string.digits, k=8))

def now():
    return datetime.datetime.utcnow().isoformat()

def dist(a,b,c,d):
    return ((a-c)**2 + (b-d)**2)**0.5 * 111

conn = sqlite3.connect("sanjeevani_final.db")
c = conn.cursor()

# ------------------ SCHEMA ------------------
c.executescript("""

CREATE TABLE cases(
    case_id TEXT PRIMARY KEY,
    patient_id TEXT,
    source_type TEXT,
    created_at TEXT
);

CREATE TABLE patient(
    case_id TEXT,
    age INT,
    gender TEXT,
    spo2 REAL,
    heart_rate INT,
    systolic_bp INT,
    symptoms TEXT
);

CREATE TABLE triage(
    case_id TEXT,
    severity INT,
    urgency TEXT,
    needs_icu INT,
    needs_vent INT,
    specialist TEXT
);

CREATE TABLE agent_decision(
    case_id TEXT,
    decision TEXT,
    confidence REAL,
    reasoning TEXT
);

CREATE TABLE hospitals(
    hospital_id TEXT PRIMARY KEY,
    name TEXT,
    lat REAL,
    lon REAL,
    has_icu INT,
    has_vent INT,
    specialists TEXT,
    max_icu INT
);

CREATE TABLE hospital_dynamic(
    hospital_id TEXT,
    available_icu INT,
    load REAL,
    intake_delay INT,
    readiness REAL
);

CREATE TABLE recommendations(
    case_id TEXT,
    hospital_id TEXT,
    eta INT,
    score REAL,
    compatibility TEXT,
    explanation TEXT
);

CREATE TABLE ambulances(
    ambulance_id TEXT PRIMARY KEY,
    lat REAL,
    lon REAL,
    status TEXT
);

CREATE TABLE ambulance_assignment(
    case_id TEXT,
    ambulance_id TEXT,
    eta_to_patient INT
);

CREATE TABLE routes(
    case_id TEXT,
    hospital_id TEXT,
    distance REAL,
    eta INT
);

CREATE TABLE notifications(
    case_id TEXT,
    hospital_id TEXT,
    severity INT,
    status TEXT
);

CREATE TABLE ehr(
    patient_id TEXT,
    conditions TEXT,
    allergies TEXT,
    risk REAL
);

CREATE TABLE unknown_patient(
    case_id TEXT,
    temp_id TEXT,
    mlc INT
);

CREATE TABLE event_logs(
    event_id TEXT PRIMARY KEY,
    case_id TEXT,
    event TEXT,
    timestamp TEXT
);

""")

# ------------------ HOSPITALS ------------------
hospitals = []
specs = ["cardio","neuro","trauma","general"]

for i in range(20):
    hid = uid("h")
    lat, lon = 19 + random.random(), 72 + random.random()
    has_icu = random.choice([0,1])
    has_vent = random.choice([0,1]) if has_icu else 0
    sp = random.sample(specs, random.randint(1,4))
    max_icu = random.randint(5,20)

    c.execute("INSERT INTO hospitals VALUES (?,?,?,?,?,?,?,?)",
              (hid, f"Hosp{i}", lat, lon, has_icu, has_vent, json.dumps(sp), max_icu))

    avail = random.randint(0, max_icu)
    load = random.uniform(30,95)
    intake = random.randint(2,20)
    readiness = (1-load/100)

    c.execute("INSERT INTO hospital_dynamic VALUES (?,?,?,?,?)",
              (hid, avail, load, intake, readiness))

    hospitals.append((hid, lat, lon, has_icu, has_vent, sp, load, intake))

# ------------------ AMBULANCES ------------------
ambulances = []
for i in range(15):
    aid = uid("amb")
    lat, lon = 19 + random.random(), 72 + random.random()
    status = random.choice(["available","available","busy"])

    c.execute("INSERT INTO ambulances VALUES (?,?,?,?)",
              (aid, lat, lon, status))

    ambulances.append((aid, lat, lon, status))

# ------------------ SCENARIOS ------------------
scenarios = [
    ("cardiac","cardio"),
    ("stroke","neuro"),
    ("accident","trauma"),
    ("burn","general")
]

# ------------------ CASE GENERATION ------------------
for _ in range(1000):

    case_id = uid("case")
    patient_id = uid("pat")

    lat, lon = 19 + random.random(), 72 + random.random()
    scenario, spec = random.choice(scenarios)

    spo2 = random.randint(80,100)
    hr = random.randint(70,140)
    bp = random.randint(90,180)

    severity = 5
    if spo2 < 88: severity += 2
    if hr > 120: severity += 1
    if bp > 170: severity += 1

    urgency = "critical" if severity >= 9 else "high" if severity >= 7 else "medium"
    needs_icu = 1 if severity >= 8 else 0
    needs_vent = 1 if spo2 < 85 else 0

    c.execute("INSERT INTO cases VALUES (?,?,?,?)",
              (case_id, patient_id, "ambulance", now()))

    c.execute("INSERT INTO patient VALUES (?,?,?,?,?,?,?)",
              (case_id, random.randint(20,80), "male", spo2, hr, bp, scenario))

    c.execute("INSERT INTO triage VALUES (?,?,?,?,?,?)",
              (case_id, severity, urgency, needs_icu, needs_vent, spec))

    # EHR / unknown
    if random.random() < 0.8:
        c.execute("INSERT INTO ehr VALUES (?,?,?,?)",
                  (patient_id, "hypertension", "none", 0.6))
    else:
        c.execute("INSERT INTO unknown_patient VALUES (?,?,?)",
                  (case_id, uid("temp"), 1))

    # Agent decision
    c.execute("INSERT INTO agent_decision VALUES (?,?,?,?)",
              (case_id, "hospital_suggestion", 0.9, "based on severity"))

    # Recommendations
    recs = []

    for h in hospitals:
        hid, hlat, hlon, icu, vent, sp, load, intake = h

        d = dist(lat, lon, hlat, hlon)
        eta = int(d/40*60)

        penalty = 0
        if spec not in sp: penalty += 20
        if needs_icu and not icu: penalty += 50

        score = eta + load + penalty

        comp = "full" if penalty == 0 else "partial" if penalty < 40 else "risky"

        recs.append((hid, eta, score, comp))

    recs.sort(key=lambda x: x[2])

    for r in recs[:3]:
        c.execute("INSERT INTO recommendations VALUES (?,?,?,?,?,?)",
                  (case_id, r[0], r[1], r[2], r[3], "optimized"))

    best = recs[0]

    # Ambulance assignment
    avail = [a for a in ambulances if a[3]=="available"]
    if not avail: avail = ambulances

    amb = min(avail, key=lambda x: dist(x[1],x[2],lat,lon))
    eta_p = int(dist(amb[1],amb[2],lat,lon)/40*60)

    c.execute("INSERT INTO ambulance_assignment VALUES (?,?,?)",
              (case_id, amb[0], eta_p))

    # Route
    c.execute("INSERT INTO routes VALUES (?,?,?,?)",
              (case_id, best[0], best[1], best[1]))

    # Notification
    c.execute("INSERT INTO notifications VALUES (?,?,?,?)",
              (case_id, best[0], severity, "sent"))

    # Logs
    steps = ["CREATED","TRIAGED","RECOMMENDED","ASSIGNED","NOTIFIED"]

    for s in steps:
        c.execute("INSERT INTO event_logs VALUES (?,?,?,?)",
                  (uid("ev"), case_id, s, now()))

conn.commit()
conn.close()

print("DONE: sanjeevani_final.db created")