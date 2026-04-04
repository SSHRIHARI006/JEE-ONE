import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class ApiService {
  // Override at run/build time for real devices:
  // --dart-define=API_BASE_URL=http://<your-laptop-lan-ip>:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.23.46.111:8000',
  );

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
  // POST /api/analyze-scene/
  // ---------------------------------------------------------------------------

  /// Sends a base64-encoded scene photo to Claude vision for analysis.
  /// Returns structured scene context (severity, injuries, hazards, etc.)
  static Future<Map<String, dynamic>> analyzeScene({
    required String imageBase64,
    required String mediaType,
  }) async {
    final url = Uri.parse('$baseUrl/api/analyze-scene/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_base64': imageBase64, 'media_type': mediaType}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Scene analysis failed: ${response.body}');
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
    Map<String, dynamic>? sceneContext,
  }) async {
    final url = Uri.parse('$baseUrl/api/sos/');

    final body = <String, dynamic>{
      "patient_id": patientId,
      "input_text": inputText,
      "source_type": sourceType,
      "vitals": {
        "spo2": spo2,
        "systolic_bp": systolicBp,
        "diastolic_bp": diastolicBp,
      },
      "location": {"latitude": latitude, "longitude": longitude},
      if (sceneContext != null) "scene_context": sceneContext,
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
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

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
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

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
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

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
