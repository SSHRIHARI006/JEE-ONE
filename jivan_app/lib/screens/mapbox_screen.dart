import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../services/mapbox_service.dart';

/// Full-screen situational map.
///
/// Receives the full SOS API response via GoRouter extra.
/// Shows:
///  • Patient marker (live GPS)
///  • All hospital markers with AI-ranked compatibility colour
///  • ORS Matrix ETA badges on each marker
///  • Mapbox driving-route polyline to the selected hospital
///  • Bottom sheet with hospital details + "Navigate" action
class MapboxScreen extends StatefulWidget {
  const MapboxScreen({super.key});

  @override
  State<MapboxScreen> createState() => _MapboxScreenState();
}

class _MapboxScreenState extends State<MapboxScreen> {
  // ── API response data ──────────────────────────────────────────────────────
  Map<String, dynamic>? _fullResponse;
  Map<String, dynamic>? _routing;
  List<Map<String, dynamic>> _allHospitals = [];

  // ── Patient GPS ────────────────────────────────────────────────────────────
  double _patientLat = 18.521;
  double _patientLng = 73.812;

  // ── Selection state ────────────────────────────────────────────────────────
  Map<String, dynamic>? _selectedHospital;

  // ── ORS Matrix ETAs: hospital_id → etaMinutes ──────────────────────────────
  Map<String, int> _orsEtas = {};
  Map<String, double> _orsDistances = {};

  // ── Mapbox route polyline ──────────────────────────────────────────────────
  List<LatLng> _routePoints = [];
  bool _routeLoading = false;

  final MapController _mapController = MapController();

  // ── Compatibility colour ───────────────────────────────────────────────────
  Color _compatColour(String? compat) {
    switch ((compat ?? '').toUpperCase()) {
      case 'FULL':
        return AppColors.success;
      case 'PARTIAL':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _initGps();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic> && _fullResponse == null) {
      _fullResponse = extra;
      _routing = extra['routing'] as Map<String, dynamic>?;

      // Collect routing + alternatives into one list
      final alts = (extra['alternatives'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      _allHospitals = [
        if (_routing != null) _routing!,
        ...alts,
      ];

      // Auto-select the top pick
      if (_allHospitals.isNotEmpty) {
        _selectedHospital = _allHospitals.first;
      }

      // Load ORS matrix + initial route after GPS ready (called again from
      // _initGps once location is resolved)
      _loadOrsMatrix();
      if (_selectedHospital != null) _loadRoute(_selectedHospital!);
    }
  }

  Future<void> _initGps() async {
    final pos = await ApiService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _patientLat = pos.latitude;
        _patientLng = pos.longitude;
      });
      // Refresh matrix with real location
      _loadOrsMatrix();
      if (_selectedHospital != null) _loadRoute(_selectedHospital!);
    }
  }

  Future<void> _loadOrsMatrix() async {
    if (_allHospitals.isEmpty) return;

    final matrix = await OrsService.getEtas(
      originLat: _patientLat,
      originLng: _patientLng,
      destinations: _allHospitals,
    );

    if (matrix == null || !mounted) return;

    final Map<String, int> etas = {};
    final Map<String, double> dists = {};
    for (int i = 0; i < _allHospitals.length; i++) {
      final id = _allHospitals[i]['hospital_id']?.toString() ?? '$i';
      etas[id] = matrix.etaMinutes(i);
      dists[id] = matrix.distanceKm(i);
    }

    setState(() {
      _orsEtas = etas;
      _orsDistances = dists;
    });
  }

  /// Returns true only when the list has ≥2 points that are NOT all identical.
  /// flutter_map 8.x asserts this before computing LatLngBounds.
  bool _hasDistinctPoints(List<LatLng> pts) =>
      pts.length >= 2 &&
      pts.any((p) =>
          p.latitude != pts.first.latitude ||
          p.longitude != pts.first.longitude);

  Future<void> _loadRoute(Map<String, dynamic> hospital) async {
    final double hLat = (hospital['latitude'] as num?)?.toDouble() ?? _patientLat;
    final double hLng = (hospital['longitude'] as num?)?.toDouble() ?? _patientLng;

    setState(() {
      _routeLoading = true;
      _routePoints = [];
    });

    try {
      final pts = await MapboxService.getRoute(
        startLat: _patientLat,
        startLng: _patientLng,
        endLat: hLat,
        endLng: hLng,
      );
      if (!mounted) return;
      setState(() {
        _routePoints = pts;
        _routeLoading = false;
      });
      // Pan map to show full route
      if (pts.isNotEmpty) {
        final mid = LatLng(
          (_patientLat + hLat) / 2,
          (_patientLng + hLng) / 2,
        );
        _mapController.move(mid, 13);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _routeLoading = false;
        _routePoints = [
          LatLng(_patientLat, _patientLng),
          LatLng(hLat, hLng),
        ];
      });
    }
  }

  void _selectHospital(Map<String, dynamic> hospital) {
    setState(() => _selectedHospital = hospital);
    _loadRoute(hospital);
  }

  @override
  Widget build(BuildContext context) {
    final LatLng patientPoint = LatLng(_patientLat, _patientLng);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: patientPoint,
              initialZoom: 13,
            ),
            children: [
              // Mapbox streets tiles
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=${MapboxService.accessToken}',
                additionalOptions: const {
                  'accessToken': MapboxService.accessToken,
                  'id': 'mapbox/streets-v11',
                },
              ),

              // Driving-route polyline
              if (_hasDistinctPoints(_routePoints))
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: AppColors.primary,
                    ),
                  ],
                ),

              // Hospital markers
              MarkerLayer(
                markers: [
                  // Patient marker
                  Marker(
                    point: patientPoint,
                    width: 60,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 14),
                        ),
                        const Text('Patient',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),

                  // Hospital markers
                  ..._allHospitals.map((h) {
                    final double hLat =
                        (h['latitude'] as num?)?.toDouble() ?? _patientLat;
                    final double hLng =
                        (h['longitude'] as num?)?.toDouble() ?? _patientLng;
                    final String hId = h['hospital_id']?.toString() ?? '';
                    final bool isSelected =
                        _selectedHospital?['hospital_id'] == hId;
                    final Color colour = _compatColour(h['compatibility']);
                    final int? orsEta = _orsEtas[hId];

                    return Marker(
                      point: LatLng(hLat, hLng),
                      width: 80,
                      height: 72,
                      child: GestureDetector(
                        onTap: () => _selectHospital(h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isSelected ? 36 : 28,
                              height: isSelected ? 36 : 28,
                              decoration: BoxDecoration(
                                color: colour,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white,
                                    width: isSelected ? 3 : 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: colour.withAlpha(80),
                                      blurRadius: isSelected ? 8 : 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Icon(Icons.local_hospital,
                                  color: Colors.white,
                                  size: isSelected ? 18 : 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colour
                                    : Colors.white.withAlpha(230),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 3)
                                ],
                              ),
                              child: Text(
                                orsEta != null ? '$orsEta min' : '-- min',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ── Back button ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/hospital-list',
                        extra: _fullResponse),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Situational Map — ${_allHospitals.length} hospitals',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_routeLoading) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom hospital card ─────────────────────────────────────────
          if (_selectedHospital != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _HospitalBottomCard(
                hospital: _selectedHospital!,
                orsEta: _orsEtas[_selectedHospital!['hospital_id']],
                orsDistance:
                    _orsDistances[_selectedHospital!['hospital_id']],
                compatColour:
                    _compatColour(_selectedHospital!['compatibility']),
                onNavigate: () => context.go(
                  '/navigation',
                  extra: {
                    'hospital': _selectedHospital,
                    'fullResponse': _fullResponse,
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom card
// ─────────────────────────────────────────────────────────────────────────────

class _HospitalBottomCard extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final int? orsEta;
  final double? orsDistance;
  final Color compatColour;
  final VoidCallback onNavigate;

  const _HospitalBottomCard({
    required this.hospital,
    required this.orsEta,
    required this.orsDistance,
    required this.compatColour,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final String name = hospital['name']?.toString() ?? 'Hospital';
    final String compat =
        (hospital['compatibility']?.toString() ?? 'PARTIAL').toUpperCase();
    final int aiEta = (hospital['eta'] as num?)?.toInt() ?? 0;
    final double aiDist =
        (hospital['distance_km'] as num?)?.toDouble() ?? 0.0;
    final double load =
        (hospital['load_percentage'] as num?)?.toDouble() ?? 0.0;
    final String explanation =
        hospital['explanation']?.toString() ?? '';

    // Prefer ORS real-world values, fall back to AI estimates
    final String etaLabel = orsEta != null ? '$orsEta min' : '$aiEta min';
    final String distLabel = orsDistance != null
        ? '${orsDistance!.toStringAsFixed(1)} km'
        : '${aiDist.toStringAsFixed(1)} km';
    final String etaSource = orsEta != null ? 'Live ORS' : 'AI estimate';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(etaSource,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: compatColour.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(compat,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: compatColour)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stats row
          Row(children: [
            _Stat(icon: Icons.access_time, label: 'ETA', value: etaLabel),
            const SizedBox(width: 10),
            _Stat(icon: Icons.route, label: 'Distance', value: distLabel),
            const SizedBox(width: 10),
            _Stat(
                icon: Icons.local_hospital_outlined,
                label: 'Load',
                value: '${load.toStringAsFixed(0)}%'),
          ]),

          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(explanation,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation_outlined, size: 18),
              label: const Text('Navigate Here',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Stat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ]),
      ),
    );
  }
}
