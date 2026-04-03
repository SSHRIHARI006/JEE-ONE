import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/primary_action_button.dart';

class TriageResultScreen extends StatelessWidget {
  const TriageResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;

    final Map<String, dynamic>? data = extra is Map<String, dynamic>
        ? extra
        : null;

    final triage = data?['triage'] as Map<String, dynamic>?;
    final diagnosis = data?['diagnosis'] as Map<String, dynamic>?;
    final advice = data?['advice'] as Map<String, dynamic>?;

    final int severity = triage?['severity'] ?? 0;
    final String urgency = triage?['urgency']?.toString() ?? 'UNKNOWN';
    final int timeToCritical = triage?['time_to_critical_minutes'] ?? 0;
    final bool needsIcu = triage?['needs_ICU'] ?? false;
    final bool needsVentilator = triage?['needs_ventilator'] ?? false;
    final String specialist =
        triage?['specialist']?.toString() ?? 'Not specified';

    final String probableDiagnosis =
        diagnosis?['probable']?.toString() ?? 'No diagnosis available';
    final String reasoning =
        diagnosis?['reasoning']?.toString() ?? 'No reasoning available';
    final String adviceMessage =
        advice?['message']?.toString() ?? 'No advice available';

    return AppShellScaffold(
      bottomNavigationBar: const _BottomNavBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandBar(onBack: () => context.go('/')),
          const SizedBox(height: 18),

          AppPageHeader(
            eyebrow: 'AI Result',
            title: 'Triage complete',
            subtitle: 'Severity and required emergency resources are ready.',
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
                    severity.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'RISK',
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

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _urgencyBg(urgency),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    urgency,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _urgencyColor(urgency),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  probableDiagnosis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reasoning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 380;

              if (stack) {
                return Column(
                  children: [
                    _KeyStatCard(
                      title: 'Time to Critical',
                      value: '$timeToCritical min',
                      icon: Icons.timer_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _KeyStatCard(
                      title: 'Severity',
                      value: severity.toString(),
                      icon: Icons.monitor_heart_outlined,
                      color: AppColors.info,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _KeyStatCard(
                      title: 'Time to Critical',
                      value: '$timeToCritical min',
                      icon: Icons.timer_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KeyStatCard(
                      title: 'Severity',
                      value: severity.toString(),
                      icon: Icons.monitor_heart_outlined,
                      color: AppColors.info,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'Required Resources',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (needsIcu)
            const _ResourceTile(
              title: 'ICU Access',
              subtitle: 'Critical stabilization bed needed on arrival',
              icon: Icons.local_hospital_outlined,
              color: AppColors.success,
              bgColor: AppColors.successSoft,
            ),

          if (needsIcu) const SizedBox(height: 10),

          if (needsVentilator)
            const _ResourceTile(
              title: 'Ventilator Support',
              subtitle: 'Respiratory backup may be required',
              icon: Icons.air,
              color: AppColors.info,
              bgColor: AppColors.infoSoft,
            ),

          if (needsVentilator) const SizedBox(height: 10),

          _ResourceTile(
            title: 'Specialist Team',
            subtitle: specialist,
            icon: Icons.groups_2_outlined,
            color: AppColors.warning,
            bgColor: AppColors.warningSoft,
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    adviceMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          PrimaryActionButton(
            label: 'View Hospital Recommendation',
            icon: Icons.arrow_forward,
            onPressed: () => context.go('/hospital-list', extra: data),
          ),
        ],
      ),
    );
  }

  static Color _urgencyBg(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'HIGH':
        return AppColors.dangerSoft;
      case 'MEDIUM':
        return AppColors.warningSoft;
      case 'LOW':
        return AppColors.successSoft;
      default:
        return AppColors.surfaceSoft;
    }
  }

  static Color _urgencyColor(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'HIGH':
        return AppColors.primary;
      case 'MEDIUM':
        return AppColors.warning;
      case 'LOW':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
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

class _KeyStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KeyStatCard({
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
              color: color.withOpacity(0.12),
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

class _ResourceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _ResourceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
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
