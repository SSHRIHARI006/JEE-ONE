import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hospital_model.dart';

class ApiService {
  // Use Android Emulator alias for localhost
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<List<HospitalModel>> getRecommendations({
    required double latitude,
    required double longitude,
    required double spo2,
    required double systolicBp,
  }) async {
    final url = Uri.parse('$baseUrl/api/rank-hospitals/');
    
    try {
      // Assuming POST request to send patient vitals and location
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'spo2': spo2,
          'systolic_bp': systolicBp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HospitalModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recommendations. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
}
