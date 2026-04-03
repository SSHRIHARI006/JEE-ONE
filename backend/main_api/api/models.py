from django.db import models

class Hospitals(models.Model):
    hospital_id = models.CharField(primary_key=True, max_length=50)
    hospital_name = models.CharField(max_length=255)
    latitude = models.FloatField()
    longitude = models.FloatField()
    hospital_type = models.CharField(max_length=50)  # e.g., 'Private'
    has_icu = models.IntegerField()                # 1 for True, 0 for False
    max_icu_beds = models.IntegerField()

    class Meta:
        db_table = 'hospitals'

class HospitalDynamicStatus(models.Model):
    hospital = models.OneToOneField(Hospitals, on_delete=models.CASCADE, primary_key=True)
    available_icu_beds = models.IntegerField()
    current_load_percentage = models.FloatField()
    avg_intake_delay = models.IntegerField()
    readiness_score = models.FloatField()
    last_updated_timestamp = models.DateTimeField()

    class Meta:
        db_table = 'hospital_dynamic_status'

class Ambulances(models.Model):
    ambulance_id = models.CharField(primary_key=True, max_length=50)
    latitude = models.FloatField()
    longitude = models.FloatField()
    status = models.CharField(max_length=50)       # e.g., 'available'
    last_updated_timestamp = models.DateTimeField()

    class Meta:
        db_table = 'ambulances'

class Patients(models.Model):
    patient_id = models.CharField(primary_key=True, max_length=50)
    age = models.IntegerField()
    gender = models.CharField(max_length=10)
    created_at = models.DateTimeField()

    class Meta:
        db_table = 'patients'

class EmergencyCases(models.Model):
    case_id = models.CharField(primary_key=True, max_length=50)
    patient = models.ForeignKey(Patients, on_delete=models.CASCADE)
    source_type = models.CharField(max_length=50)  # e.g., 'ambulance'
    timestamp = models.DateTimeField()
    latitude = models.FloatField()
    longitude = models.FloatField()
    spo2 = models.IntegerField()
    systolic_bp = models.IntegerField()
    severity_score = models.IntegerField()
    urgency_level = models.CharField(max_length=50)
    required_specialist = models.CharField(max_length=50)

    class Meta:
        db_table = 'emergency_cases'

class Triage(models.Model):
    case = models.OneToOneField(EmergencyCases, on_delete=models.CASCADE, primary_key=True)
    severity_score = models.IntegerField()
    urgency_level = models.CharField(max_length=50)
    needs_icu = models.IntegerField()
    required_specialist = models.CharField(max_length=50)

    class Meta:
        db_table = 'triage'

class Recommendations(models.Model):
    # Note: Recommendations uses (cid, hid) as a composite-like structure, 
    # but Django works best with a primary key.
    case = models.ForeignKey(EmergencyCases, on_delete=models.CASCADE)
    hospital = models.ForeignKey(Hospitals, on_delete=models.CASCADE)
    eta = models.IntegerField()
    score = models.FloatField()
    compatibility = models.CharField(max_length=50)

    class Meta:
        db_table = 'recommendations'

class AmbulanceAssignment(models.Model):
    case = models.OneToOneField(EmergencyCases, on_delete=models.CASCADE, primary_key=True)
    ambulance = models.ForeignKey(Ambulances, on_delete=models.CASCADE)
    eta_to_patient = models.IntegerField()

    class Meta:
        db_table = 'ambulance_assignment'

class EventLogs(models.Model):
    event_id = models.CharField(primary_key=True, max_length=50)
    case = models.ForeignKey(EmergencyCases, on_delete=models.CASCADE)
    event_type = models.CharField(max_length=50)   # e.g., 'CREATED'
    timestamp = models.DateTimeField()

    class Meta:
        db_table = 'event_logs'