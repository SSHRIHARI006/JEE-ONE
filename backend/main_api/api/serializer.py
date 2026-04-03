from rest_framework import serializers
from .models import Hospitals, HospitalDynamicStatus, EmergencyCases, Patients

class HospitalStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = HospitalDynamicStatus
        fields = ['available_icu_beds', 'current_load_percentage', 'avg_intake_delay', 'readiness_score']

class HospitalSerializer(serializers.ModelSerializer):
    # This nests the live bed data inside the hospital object
    dynamic_info = HospitalStatusSerializer(source='hospitaldynamicstatus', read_only=True)

    class Meta:
        model = Hospitals
        fields = ['hospital_id', 'hospital_name', 'latitude', 'longitude', 'max_icu_beds', 'dynamic_info']

class EmergencyCaseSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyCases
        fields = '__all__'