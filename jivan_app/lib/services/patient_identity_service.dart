import 'package:shared_preferences/shared_preferences.dart';

class PatientIdentityService {
  static const String _key = 'jivan_patient_id';

  static Future<String> getOrCreatePatientId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = 'PATIENT-${DateTime.now().millisecondsSinceEpoch % 100000}';
    await prefs.setString(_key, generated);
    return generated;
  }
}
