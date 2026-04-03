# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models


class AmbulanceAssignments(models.Model):
    assignment_id = models.AutoField(primary_key=True)
    case = models.ForeignKey('EmergencyCases', models.DO_NOTHING, blank=True, null=True)
    ambulance = models.ForeignKey('Ambulances', models.DO_NOTHING, blank=True, null=True)
    eta_to_patient = models.IntegerField(blank=True, null=True)
    status = models.CharField(max_length=12, blank=True, null=True)
    assigned_timestamp = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'ambulance_assignments'


class Ambulances(models.Model):
    ambulance_id = models.CharField(primary_key=True, max_length=100)
    latitude = models.DecimalField(max_digits=10, decimal_places=8, blank=True, null=True)
    longitude = models.DecimalField(max_digits=11, decimal_places=8, blank=True, null=True)
    status = models.CharField(max_length=9, blank=True, null=True)
    assigned_case_id = models.CharField(max_length=100, blank=True, null=True)
    last_updated_timestamp = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'ambulances'


class EhrRecords(models.Model):
    patient = models.OneToOneField('Patients', models.DO_NOTHING, primary_key=True)
    risk_score = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    last_updated = models.DateTimeField(blank=True, null=True)
    medical_history_json = models.JSONField(blank=True, null=True)
    allergies_json = models.JSONField(blank=True, null=True)
    medications_json = models.JSONField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'ehr_records'


class EmergencyCases(models.Model):
    case_id = models.CharField(primary_key=True, max_length=100)
    patient = models.ForeignKey('Patients', models.DO_NOTHING, blank=True, null=True)
    source_type = models.CharField(max_length=9)
    timestamp = models.DateTimeField()
    latitude = models.DecimalField(max_digits=10, decimal_places=8, blank=True, null=True)
    longitude = models.DecimalField(max_digits=11, decimal_places=8, blank=True, null=True)
    heart_rate = models.IntegerField(blank=True, null=True)
    systolic_bp = models.IntegerField(blank=True, null=True)
    diastolic_bp = models.IntegerField(blank=True, null=True)
    spo2 = models.DecimalField(max_digits=4, decimal_places=1, blank=True, null=True)
    respiratory_rate = models.IntegerField(blank=True, null=True)
    temperature = models.DecimalField(max_digits=4, decimal_places=1, blank=True, null=True)
    conscious = models.IntegerField(blank=True, null=True)
    breathing = models.IntegerField(blank=True, null=True)
    bleeding = models.IntegerField(blank=True, null=True)
    injury_type = models.CharField(max_length=100, blank=True, null=True)
    pain_level = models.IntegerField(blank=True, null=True)
    time_since_incident = models.IntegerField(blank=True, null=True)
    severity_score = models.IntegerField(blank=True, null=True)
    urgency_level = models.CharField(max_length=8, blank=True, null=True)
    needs_icu = models.IntegerField(db_column='needs_ICU', blank=True, null=True)  # Field name made lowercase.
    needs_ventilator = models.IntegerField(blank=True, null=True)
    needs_surgery = models.IntegerField(blank=True, null=True)
    required_specialist = models.CharField(max_length=100, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'emergency_cases'


class EventLogs(models.Model):
    event_id = models.CharField(primary_key=True, max_length=100)
    case = models.ForeignKey(EmergencyCases, models.DO_NOTHING, blank=True, null=True)
    event_type = models.CharField(max_length=18, blank=True, null=True)
    metadata = models.JSONField(blank=True, null=True)
    timestamp = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'event_logs'


class HospitalDynamicStatus(models.Model):
    hospital = models.OneToOneField('Hospitals', on_delete=models.CASCADE, primary_key=True)
    available_icu_beds = models.IntegerField(db_column='available_ICU_beds', blank=True, null=True)  # Field name made lowercase.
    available_ventilators = models.IntegerField(blank=True, null=True)
    available_general_beds = models.IntegerField(blank=True, null=True)
    current_load_percentage = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    avg_intake_delay = models.IntegerField(blank=True, null=True)
    status = models.CharField(max_length=14, blank=True, null=True)
    staff_availability_score = models.DecimalField(max_digits=3, decimal_places=2, blank=True, null=True)
    readiness_score = models.DecimalField(max_digits=3, decimal_places=2, blank=True, null=True)
    last_updated_timestamp = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'hospital_dynamic_status'


class HospitalRecommendations(models.Model):
    recommendation_id = models.AutoField(primary_key=True)
    case = models.ForeignKey(EmergencyCases, models.DO_NOTHING, blank=True, null=True)
    hospital = models.ForeignKey('Hospitals', models.DO_NOTHING, blank=True, null=True)
    eta = models.IntegerField(blank=True, null=True)
    distance_km = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    compatibility = models.CharField(max_length=7, blank=True, null=True)
    score = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    explanation = models.TextField(blank=True, null=True)
    generated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'hospital_recommendations'


class Hospitals(models.Model):
    hospital_id = models.CharField(primary_key=True, max_length=100)
    hospital_name = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=10, decimal_places=8)
    longitude = models.DecimalField(max_digits=11, decimal_places=8)
    hospital_type = models.CharField(max_length=50, blank=True, null=True)
    avg_treatment_time = models.IntegerField(blank=True, null=True)
    has_icu = models.IntegerField(db_column='has_ICU', blank=True, null=True)  # Field name made lowercase.
    has_ventilator = models.IntegerField(blank=True, null=True)
    has_ct_scan = models.IntegerField(db_column='has_CT_scan', blank=True, null=True)  # Field name made lowercase.
    has_mri = models.IntegerField(db_column='has_MRI', blank=True, null=True)  # Field name made lowercase.
    max_icu_beds = models.IntegerField(db_column='max_ICU_beds', blank=True, null=True)  # Field name made lowercase.
    max_ventilators = models.IntegerField(blank=True, null=True)
    max_general_beds = models.IntegerField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'hospitals'


class Patients(models.Model):
    patient_id = models.CharField(primary_key=True, max_length=100)
    age = models.IntegerField(blank=True, null=True)
    gender = models.CharField(max_length=20, blank=True, null=True)
    weight = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'patients'


class Routes(models.Model):
    case = models.OneToOneField(EmergencyCases, models.DO_NOTHING, primary_key=True)
    destination_hospital_id = models.CharField(max_length=100, blank=True, null=True)
    distance_km = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    estimated_travel_time = models.IntegerField(blank=True, null=True)
    traffic_level = models.CharField(max_length=6, blank=True, null=True)
    route_polyline = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'routes'


class UnknownPatients(models.Model):
    temp_patient_id = models.CharField(primary_key=True, max_length=100)
    case = models.ForeignKey(EmergencyCases, models.DO_NOTHING, blank=True, null=True)
    biometric_data_available = models.IntegerField(blank=True, null=True)
    mlc_flag = models.IntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'unknown_patients'
