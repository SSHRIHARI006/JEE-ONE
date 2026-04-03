import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../services/mapbox_service.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/primary_action_button.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  List<LatLng> routePoints = [];
  bool isLoadingRoute = true;
  String? routeError;

  late Map<String, dynamic>? navData;
  late Map<String, dynamic>? hospital;
  late Map<String, dynamic>? fullResponse;

  late String hospitalName;
  late int eta;
  late num distance;
  late String explanation;
  late double hospitalLat;
  late double hospitalLng;

  // Patient / ambulance live GPS — resolved in initState, fallback to Pune centre
  double patientLat = 18.521;
  double patientLng = 73.812;

  @override
  void initState() {
    super.initState();
    _initPatientLocation();
  }

  bool _hasDistinctPoints(List<LatLng> pts) {
    if (pts.length < 2) return false;
    // Reject any point outside geographic bounds (catches decoder overflow)
    if (pts.any((p) => p.latitude.abs() > 90 || p.longitude.abs() > 180)) {
      return false;
    }
    return pts.any((p) =>
        p.latitude != pts.first.latitude ||
        p.longitude != pts.first.longitude);
  }

  Future<void> _initPatientLocation() async {
    final pos = await ApiService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        patientLat = pos.latitude;
        patientLng = pos.longitude;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final extra = GoRouterState.of(context).extra;
    navData = extra is Map<String, dynamic> ? extra : null;

    hospital = navData?['hospital'] as Map<String, dynamic>?;
    fullResponse = navData?['fullResponse'] as Map<String, dynamic>?;

    hospitalName = hospital?['name']?.toString() ?? 'Selected Hospital';
    eta = (hospital?['eta'] as num?)?.toInt() ?? 0;
    distance = (hospital?['distance_km'] as num?) ?? 0;
    explanation = hospital?['explanation']?.toString() ?? 'Route ready';

    hospitalLat = (hospital?['latitude'] as num?)?.toDouble() ?? 18.5015;
    hospitalLng = (hospital?['longitude'] as num?)?.toDouble() ?? 73.8205;

    if (routePoints.isEmpty && isLoadingRoute) {
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    try {
      // Fetch Mapbox driving route
      final points = await MapboxService.getRoute(
        startLat: patientLat,
        startLng: patientLng,
        endLat: hospitalLat,
        endLng: hospitalLng,
      );

      // Refine ETA with ORS Matrix
      final matrix = await OrsService.getEtas(
        originLat: patientLat,
        originLng: patientLng,
        destinations: [
          {'latitude': hospitalLat, 'longitude': hospitalLng},
        ],
      );

      if (!mounted) return;
      setState(() {
        routePoints = points;
        isLoadingRoute = false;
        if (matrix != null) {
          eta = matrix.etaMinutes(0);
          distance = matrix.distanceKm(0);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        routeError = e.toString();
        isLoadingRoute = false;
        routePoints = [
          LatLng(patientLat, patientLng),
          LatLng(hospitalLat, hospitalLng),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng patientPoint = LatLng(patientLat, patientLng);
    final LatLng hospitalPoint = LatLng(hospitalLat, hospitalLng);

    return AppShellScaffold(
      bottomNavigationBar: const _BottomNavBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandBar(
            onBack: () => context.go('/hospital-list', extra: fullResponse),
          ),
          const SizedBox(height: 18),

          AppPageHeader(
            eyebrow: 'Navigation',
            title: 'Route to hospital',
            subtitle: hospitalName,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eta.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'MIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Route',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: isLoadingRoute
                        ? const Center(child: CircularProgressIndicator())
                        : FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                (patientLat + hospitalLat) / 2,
                                (patientLng + hospitalLng) / 2,
                              ),
                              initialZoom: 13.2,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=${MapboxService.accessToken}',
                                additionalOptions: const {
                                  'accessToken': MapboxService.accessToken,
                                  'id': 'mapbox/streets-v11',
                                },
                              ),
                              if (_hasDistinctPoints(routePoints))
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: routePoints,
                                      strokeWidth: 5,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: patientPoint,
                                    width: 70,
                                    height: 70,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 18,
                                          width: 18,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Patient',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Marker(
                                    point: hospitalPoint,
                                    width: 90,
                                    height: 90,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 42,
                                          width: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.info,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.local_hospital,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          hospitalName,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  explanation,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (routeError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Route fallback used: $routeError',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _RouteStatCard(
                  title: 'Distance',
                  value: '${distance.toString()} km',
                  icon: Icons.route_outlined,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RouteStatCard(
                  title: 'ETA',
                  value: '$eta min',
                  icon: Icons.access_time,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          PrimaryActionButton(
            label: 'Continue to Handover',
            icon: Icons.arrow_forward,
            onPressed: () => context.go('/handover'),
          ),
        ],
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  final VoidCallback onBack;
  const _BrandBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Jeevan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _RouteStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _RouteStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_filled, label: 'Home'),
          _NavItem(icon: Icons.history, label: 'History'),
          _NavItem(
            icon: Icons.local_hospital_outlined,
            label: 'Hospitals',
            active: true,
          ),
          _NavItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: active ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
