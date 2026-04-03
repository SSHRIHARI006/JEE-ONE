import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/primary_action_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      bottomNavigationBar: const _BottomNavBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 2,
        onPressed: () => context.go('/emergency-reporting'),
        child: const Icon(Icons.call, color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandBar(),
          const SizedBox(height: 18),

          AppPageHeader(
            eyebrow: 'Emergency Response',
            title: 'Fast help. Clear actions.',
            subtitle:
                'Report an emergency, start ambulance intake, or continue an active case.',
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
                    '24/7',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'READY',
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

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool isTight = constraints.maxWidth < 430;

              if (isTight) {
                return Column(
                  children: [
                    PrimaryActionButton(
                      label: 'Report Emergency',
                      icon: Icons.arrow_forward,
                      onPressed: () => context.go('/emergency-reporting'),
                    ),
                    const SizedBox(height: 12),
                    _SecondaryActionButton(
                      label: 'Ambulance Mode',
                      icon: Icons.local_hospital,
                      onPressed: () => context.go('/case-intake'),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: PrimaryActionButton(
                      label: 'Report Emergency',
                      icon: Icons.arrow_forward,
                      onPressed: () => context.go('/emergency-reporting'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SecondaryActionButton(
                      label: 'Ambulance Mode',
                      icon: Icons.local_hospital,
                      onPressed: () => context.go('/case-intake'),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 22),

          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 520;
              final double itemWidth = isSmall
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _QuickCard(
                      icon: Icons.local_hospital_outlined,
                      iconBg: AppColors.infoSoft,
                      iconColor: AppColors.info,
                      title: 'Hospitals',
                      subtitle: 'See best facility options',
                      onTap: () => context.go('/hospital-list'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _QuickCard(
                      icon: Icons.route_outlined,
                      iconBg: AppColors.warningSoft,
                      iconColor: AppColors.warning,
                      title: 'Navigation',
                      subtitle: 'Open route and ETA',
                      onTap: () => context.go('/navigation'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _QuickCard(
                      icon: Icons.fingerprint,
                      iconBg: AppColors.surfaceSoft,
                      iconColor: AppColors.textPrimary,
                      title: 'Biometric',
                      subtitle: 'Identify patient quickly',
                      onTap: () => context.go('/biometric'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _QuickCard(
                      icon: Icons.analytics_outlined,
                      iconBg: AppColors.dangerSoft,
                      iconColor: AppColors.primary,
                      title: 'AI Dashboard',
                      subtitle: 'Explain triage logic',
                      onTap: () => context.go('/explainability'),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'Active Case',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'CRITICAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Text(
                      'Case #492-B',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Trauma Alpha',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hospital alerted. ICU requested. Route synced.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool stack = constraints.maxWidth < 360;

                    if (stack) {
                      return Column(
                        children: const [
                          _CaseStatCard(title: 'ETA', value: '08 min'),
                          SizedBox(height: 10),
                          _CaseStatCard(title: 'Hospital', value: 'St. Mary’s'),
                          SizedBox(height: 10),
                          _CaseStatCard(title: 'Status', value: 'En Route'),
                        ],
                      );
                    }

                    return const Row(
                      children: [
                        Expanded(
                          child: _CaseStatCard(title: 'ETA', value: '08 min'),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _CaseStatCard(
                            title: 'Hospital',
                            value: 'St. Mary’s',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _CaseStatCard(
                            title: 'Status',
                            value: 'En Route',
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                PrimaryActionButton(
                  label: 'Open Handover',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go('/handover'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '✱',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Jeevan',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
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
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseStatCard extends StatelessWidget {
  final String title;
  final String value;

  const _CaseStatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
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
          _NavItem(icon: Icons.home_filled, label: 'Home', active: true),
          _NavItem(icon: Icons.history, label: 'History'),
          _NavItem(icon: Icons.local_hospital_outlined, label: 'Hospitals'),
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
