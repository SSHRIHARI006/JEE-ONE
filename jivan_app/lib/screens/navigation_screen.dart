import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/primary_action_button.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      bottomNavigationBar: const _BottomNavBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandBar(onBack: () => context.go('/hospital-list')),
          const SizedBox(height: 18),

          AppPageHeader(
            eyebrow: 'Navigation',
            title: 'Route to hospital',
            subtitle:
                'Follow the fastest current path to the selected facility.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '08',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
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
                const Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _StatusTag(
                      label: 'FASTEST ROUTE',
                      bgColor: AppColors.infoSoft,
                      textColor: AppColors.info,
                    ),
                    _StatusTag(
                      label: 'LIVE TRACKING',
                      bgColor: AppColors.dangerSoft,
                      textColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'City General Hospital',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Marine Drive, Mumbai',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _RouteMapPainter()),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.traffic,
                                size: 16,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Traffic +2 min',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 26,
                        right: 28,
                        child: Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 28,
                        left: 34,
                        child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 400;

              if (stack) {
                return Column(
                  children: const [
                    _RouteStatCard(
                      title: 'Distance',
                      value: '3.8 km',
                      icon: Icons.route_outlined,
                      color: AppColors.info,
                    ),
                    SizedBox(height: 10),
                    _RouteStatCard(
                      title: 'Traffic Delay',
                      value: '+2 min',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                    SizedBox(height: 10),
                    _RouteStatCard(
                      title: 'Arrival ETA',
                      value: '14:22',
                      icon: Icons.access_time,
                      color: AppColors.primary,
                    ),
                  ],
                );
              }

              return const Row(
                children: [
                  Expanded(
                    child: _RouteStatCard(
                      title: 'Distance',
                      value: '3.8 km',
                      icon: Icons.route_outlined,
                      color: AppColors.info,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _RouteStatCard(
                      title: 'Traffic Delay',
                      value: '+2 min',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _RouteStatCard(
                      title: 'Arrival ETA',
                      value: '14:22',
                      icon: Icons.access_time,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          PrimaryActionButton(
            label: 'Continue to Handover',
            icon: Icons.arrow_forward,
            onPressed: () => context.go('/handover'),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.call_outlined),
              label: const Text(
                'Contact Hospital',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
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
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.textPrimary,
            ),
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
        const Spacer(),
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.notifications_none,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _StatusTag({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 12),
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
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = const Color(0xFFDADFE5)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final Paint routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.82);
    path.quadraticBezierTo(
      size.width * 0.28,
      size.height * 0.62,
      size.width * 0.42,
      size.height * 0.55,
    );
    path.quadraticBezierTo(
      size.width * 0.62,
      size.height * 0.46,
      size.width * 0.78,
      size.height * 0.18,
    );

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.dangerSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
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
      ),
    );
  }
}
