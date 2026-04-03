import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> submitSosCase({
    required String patientId,
    required String inputText,
    required int spo2,
    required int systolicBp,
    required int diastolicBp,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$baseUrl/api/sos/');

    final body = {
      "patient_id": patientId,
      "input_text": inputText,
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
    } else {
      throw Exception('Failed to submit SOS case: ${response.body}');
    }
  }
}
