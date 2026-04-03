class HospitalModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int etaMinutes;
  final int availableIcuBeds;
  final int currentLoadPercentage;
  final String specialty;

  HospitalModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.etaMinutes,
    required this.availableIcuBeds,
    required this.currentLoadPercentage,
    required this.specialty,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Hospital',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      etaMinutes: json['eta_minutes'] ?? 0,
      availableIcuBeds: json['available_icu_beds'] ?? 0,
      currentLoadPercentage: json['current_load_percentage'] ?? 0,
      specialty: json['specialty'] ?? 'General',
    );
  }
}
