import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ---------------------------------------------------------------------------
  // GPS helper
  // ---------------------------------------------------------------------------

  /// Returns the device's current GPS position.
  /// Handles permission requests automatically.
  /// Returns null if location is unavailable or denied.
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // ---------------------------------------------------------------------------
  // POST /api/sos/
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> submitSosCase({
    required String patientId,
    required String inputText,
    required int spo2,
    required int systolicBp,
    required int diastolicBp,
    required double latitude,
    required double longitude,
    String sourceType = 'ambulance',
  }) async {
    final url = Uri.parse('$baseUrl/api/sos/');

    final body = {
      "patient_id": patientId,
      "input_text": inputText,
      "source_type": sourceType,
      "vitals": {
        "spo2": spo2,
        "systolic_bp": systolicBp,
        "diastolic_bp": diastolicBp,
      },
      "location": {"latitude": latitude, "longitude": longitude},
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('SOS submission failed: ${response.body}');
  }

  // ---------------------------------------------------------------------------
  // GET /api/cases/
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getCases() async {
    final url = Uri.parse('$baseUrl/api/cases/');
    final response = await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch cases: ${response.body}');
  }

  // ---------------------------------------------------------------------------
  // GET /api/cases/<case_id>/
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getCaseDetail(String caseId) async {
    final url = Uri.parse('$baseUrl/api/cases/$caseId/');
    final response = await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch case $caseId: ${response.body}');
  }

  // ---------------------------------------------------------------------------
  // GET /api/ambulances/
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getAmbulances() async {
    final url = Uri.parse('$baseUrl/api/ambulances/');
    final response = await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch ambulances: ${response.body}');
  }

  // ---------------------------------------------------------------------------
  // PATCH /api/ambulances/<id>/location/
  // ---------------------------------------------------------------------------

  static Future<void> updateAmbulanceLocation({
    required String ambulanceId,
    required double latitude,
    required double longitude,
    String? status,
  }) async {
    final url = Uri.parse('$baseUrl/api/ambulances/$ambulanceId/location/');
    final body = <String, dynamic>{
      "latitude": latitude,
      "longitude": longitude,
      if (status != null) "status": status,
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update ambulance location: ${response.body}');
    }
  }
}
