import 'package:flutter/material.dart';
import '../models/hospital_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  // Selected incident type
  String? incidentType;
  
  // Vitals
  double? currentSpo2;
  double? currentHeartRate;
  double? currentSystolicBp;
  
  // Severity logic
  int severity = 5;

  // Recommendations
  List<HospitalModel> recommendations = [];
  bool isLoadingRecommendations = false;
  
  // Location
  Position? currentPosition;

  void reportIncidentType(String type) {
    incidentType = type;
    notifyListeners();
  }

  void updateVitals({
    required double spo2,
    required double heartRate,
    required double systolicBp,
  }) {
    currentSpo2 = spo2;
    currentHeartRate = heartRate;
    currentSystolicBp = systolicBp;
    
    // Triage logic: Local execution
    severity = 5 + (spo2 < 88 ? 2 : 0) + (systolicBp > 170 ? 2 : 0);
    
    notifyListeners();
  }

  Future<void> fetchHospitalRecommendations() async {
    isLoadingRecommendations = true;
    notifyListeners();

    try {
      // Get location (will use fallback if GPS disabled)
      currentPosition = await _locationService.getCurrentLocation();
      
      // Fetch recommendations based on location and vitals
      recommendations = await _apiService.getRecommendations(
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
        spo2: currentSpo2 ?? 95.0, // fallback if not set
        systolicBp: currentSystolicBp ?? 120.0,
      );
    } catch (e) {
      print("Error fetching recommendations: $e");
      // Set empty or handle error
      recommendations = [];
    } finally {
      isLoadingRecommendations = false;
      notifyListeners();
    }
  }
}
