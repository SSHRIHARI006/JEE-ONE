from rest_framework import serializers
from .models import (
    Hospitals, HospitalDynamicStatus, EmergencyCases,
    Ambulances, Recommendations,
)


class HospitalStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = HospitalDynamicStatus
        fields = ['available_icu_beds', 'current_load_percentage', 'avg_intake_delay', 'readiness_score']


class HospitalSerializer(serializers.ModelSerializer):
    dynamic_info = HospitalStatusSerializer(source='hospitaldynamicstatus', read_only=True)

    class Meta:
        model = Hospitals
        fields = ['hospital_id', 'hospital_name', 'latitude', 'longitude', 'max_icu_beds', 'dynamic_info']


class AmbulanceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ambulances
        fields = ['ambulance_id', 'latitude', 'longitude', 'status', 'last_updated_timestamp']


class RecommendationWithHospitalSerializer(serializers.ModelSerializer):
    hospital_id = serializers.CharField(source='hospital.hospital_id')
    hospital_name = serializers.CharField(source='hospital.hospital_name')
    latitude = serializers.FloatField(source='hospital.latitude')
    longitude = serializers.FloatField(source='hospital.longitude')
    available_icu_beds = serializers.SerializerMethodField()
    load_percentage = serializers.SerializerMethodField()

    class Meta:
        model = Recommendations
        fields = [
            'hospital_id', 'hospital_name', 'latitude', 'longitude',
            'eta', 'score', 'compatibility', 'available_icu_beds', 'load_percentage',
        ]

    def get_available_icu_beds(self, obj):
        try:
            return obj.hospital.hospitaldynamicstatus.available_icu_beds
        except Exception:
            return 0

    def get_load_percentage(self, obj):
        try:
            return round(obj.hospital.hospitaldynamicstatus.current_load_percentage, 1)
        except Exception:
            return 0.0


class ActiveCaseSerializer(serializers.ModelSerializer):
    patient_id = serializers.CharField(source='patient.patient_id')
    hospitals = serializers.SerializerMethodField()
    ambulance = serializers.SerializerMethodField()
    needs_icu = serializers.SerializerMethodField()
    scene_context = serializers.SerializerMethodField()

    class Meta:
        model = EmergencyCases
        fields = [
            'case_id', 'patient_id', 'source_type', 'timestamp',
            'latitude', 'longitude', 'spo2', 'systolic_bp',
            'severity_score', 'urgency_level', 'required_specialist',
            'needs_icu', 'hospitals', 'ambulance', 'scene_context',
        ]

    def get_hospitals(self, obj):
        recs = (
            Recommendations.objects
            .filter(case=obj)
            .select_related('hospital', 'hospital__hospitaldynamicstatus')
            .order_by('score')[:3]
        )
        return RecommendationWithHospitalSerializer(recs, many=True).data

    def get_ambulance(self, obj):
        try:
            assignment = obj.ambulanceassignment
            return {
                'id': assignment.ambulance.ambulance_id,
                'eta_to_patient': assignment.eta_to_patient,
                'status': assignment.ambulance.status,
                'latitude': assignment.ambulance.latitude,
                'longitude': assignment.ambulance.longitude,
            }
        except Exception:
            return None

    def get_needs_icu(self, obj):
        try:
            return bool(obj.triage.needs_icu)
        except Exception:
            return False

    def get_scene_context(self, obj):
        import json
        if obj.scene_context:
            try:
                return json.loads(obj.scene_context)
            except Exception:
                return None
        return None


class EmergencyCaseSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyCases
        fields = '__all__'
