import 'package:geolocator/geolocator.dart';

class LocationService {
  // Hardcoded Pune, MIT-WPU coordinates as fallback
  static const double fallbackLat = 18.5185;
  static const double fallbackLng = 73.8152;

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _getFallbackPosition();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _getFallbackPosition();
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return _getFallbackPosition();
    } 

    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      return _getFallbackPosition();
    }
  }

  Position _getFallbackPosition() {
    return Position(
      longitude: fallbackLng,
      latitude: fallbackLat,
      timestamp: DateTime.now(),
      accuracy: 100,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
