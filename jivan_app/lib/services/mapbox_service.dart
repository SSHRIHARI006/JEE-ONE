import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mapbox Directions
// ─────────────────────────────────────────────────────────────────────────────

class MapboxService {
  // Token stored as default value so it works without --dart-define
  static const String accessToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: 'mapbox_api',
  );

  /// Returns driving route coordinates between two points.
  ///
  /// Uses `geometries=geojson` so coordinates are plain [lng, lat] arrays —
  /// no custom polyline decoder is needed (and Dart web bitwise overflow is
  /// completely avoided).
  static Future<List<LatLng>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/'
      '$startLng,$startLat;$endLng,$endLat'
      '?geometries=geojson&overview=full&access_token=$accessToken',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Mapbox route failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List?;

    if (routes == null || routes.isEmpty) {
      throw Exception('No route found from Mapbox');
    }

    // GeoJSON geometry: { "type": "LineString", "coordinates": [[lng, lat], ...] }
    final geometry = routes.first['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    return coordinates
        .map(
          (c) => LatLng(
            (c[1] as num).toDouble(), // latitude
            (c[0] as num).toDouble(), // longitude
          ),
        )
        .where((p) => p.latitude.abs() <= 90 && p.longitude.abs() <= 180)
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORS Matrix  — driving-time ETAs from one origin to N destinations
// ─────────────────────────────────────────────────────────────────────────────

class OrsMatrixResult {
  final List<double> durationsSeconds; // one entry per destination
  final List<double> distancesMetres;

  const OrsMatrixResult({
    required this.durationsSeconds,
    required this.distancesMetres,
  });

  /// ETA in whole minutes for destination [index].
  int etaMinutes(int index) =>
      (durationsSeconds[index] / 60).ceil().clamp(1, 999);

  /// Distance in km rounded to 1 decimal for destination [index].
  double distanceKm(int index) =>
      double.parse((distancesMetres[index] / 1000).toStringAsFixed(1));
}

class OrsService {
  static const String _apiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjMyMGNjOGI4ODc2YTQ4NTI4ZTMzNmYwNGI3NjE0YmNiIiwiaCI6Im11cm11cjY0In0=';

  static const String _matrixUrl =
      'https://api.openrouteservice.org/v2/matrix/driving-car';

  /// Calls ORS Matrix to get driving ETAs from [originLat/Lng] to each
  /// hospital in [destinations] (list of {latitude, longitude} maps).
  ///
  /// Returns null on network / parsing errors (caller falls back to AI ETAs).
  static Future<OrsMatrixResult?> getEtas({
    required double originLat,
    required double originLng,
    required List<Map<String, dynamic>> destinations,
  }) async {
    if (destinations.isEmpty) return null;

    // ORS format: [[lng, lat], ...]  — origin first, then destinations
    final List<List<double>> locations = [
      [originLng, originLat],
      for (final d in destinations)
        [(d['longitude'] as num).toDouble(), (d['latitude'] as num).toDouble()],
    ];

    final body = jsonEncode({
      'locations': locations,
      'sources': [0],
      'destinations': List.generate(destinations.length, (i) => i + 1),
      'metrics': ['duration', 'distance'],
    });

    try {
      final res = await http.post(
        Uri.parse(_matrixUrl),
        headers: {'Authorization': _apiKey, 'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final rawDurations = (data['durations'] as List).first as List;
      final rawDistances = (data['distances'] as List).first as List;

      return OrsMatrixResult(
        durationsSeconds: rawDurations
            .map((v) => (v as num).toDouble())
            .toList(),
        distancesMetres: rawDistances
            .map((v) => (v as num).toDouble())
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }
}
