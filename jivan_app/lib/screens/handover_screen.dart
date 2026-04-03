import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/primary_action_button.dart';

class HandoverScreen extends StatelessWidget {
  const HandoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      bottomNavigationBar: const _BottomNavBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandBar(onBack: () => context.go('/navigation')),
          const SizedBox(height: 18),

          AppPageHeader(
            eyebrow: 'Handover',
            title: 'Hospital ready',
            subtitle: 'Receiving team has been prepared for patient arrival.',
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
                    '04',
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

          const SizedBox(height: 20),

          const Text(
            'Ready Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 430;

              if (stack) {
                return const Column(
                  children: [
                    _StatusCard(
                      icon: Icons.bed_outlined,
                      title: 'ICU Reserved',
                      value: 'Bed 12 Locked',
                      color: AppColors.success,
                      bgColor: AppColors.successSoft,
                    ),
                    SizedBox(height: 10),
                    _StatusCard(
                      icon: Icons.notifications_active_outlined,
                      title: 'Hospital Notified',
                      value: 'Confirmed 14:32',
                      color: AppColors.info,
                      bgColor: AppColors.infoSoft,
                    ),
                    SizedBox(height: 10),
                    _StatusCard(
                      icon: Icons.groups_2_outlined,
                      title: 'Team Ready',
                      value: 'Bay 3 Standby',
                      color: AppColors.warning,
                      bgColor: AppColors.warningSoft,
                    ),
                  ],
                );
              }

              return const Row(
                children: [
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.bed_outlined,
                      title: 'ICU Reserved',
                      value: 'Bed 12 Locked',
                      color: AppColors.success,
                      bgColor: AppColors.successSoft,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.notifications_active_outlined,
                      title: 'Hospital Notified',
                      value: 'Confirmed 14:32',
                      color: AppColors.info,
                      bgColor: AppColors.infoSoft,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.groups_2_outlined,
                      title: 'Team Ready',
                      value: 'Bay 3 Standby',
                      color: AppColors.warning,
                      bgColor: AppColors.warningSoft,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                _ProgressRow(
                  title: 'Ambulance en route',
                  status: 'Done',
                  statusColor: AppColors.success,
                ),
                SizedBox(height: 12),
                _ProgressRow(
                  title: 'Hospital notified',
                  status: 'Done',
                  statusColor: AppColors.success,
                ),
                SizedBox(height: 12),
                _ProgressRow(
                  title: 'Medical team ready',
                  status: 'Active',
                  statusColor: AppColors.warning,
                ),
                SizedBox(height: 12),
                _ProgressRow(
                  title: 'Final handover',
                  status: 'Pending',
                  statusColor: AppColors.textMuted,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Critical Alert',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Severe allergy: Penicillin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ensure allergy warning is communicated before medication or surgical prep.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool stack = constraints.maxWidth < 340;

                    if (stack) {
                      return const Column(
                        children: [
                          _AlertInfoCard(
                            title: 'Blood Type',
                            value: 'O Negative',
                          ),
                          SizedBox(height: 10),
                          _AlertInfoCard(title: 'Age', value: '34 Years'),
                        ],
                      );
                    }

                    return const Row(
                      children: [
                        Expanded(
                          child: _AlertInfoCard(
                            title: 'Blood Type',
                            value: 'O Negative',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _AlertInfoCard(
                            title: 'Age',
                            value: '34 Years',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          PrimaryActionButton(
            label: 'Confirm Handover',
            icon: Icons.check,
            onPressed: () => context.go('/'),
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

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
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
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;

  const _ProgressRow({
    required this.title,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          status == 'Done'
              ? Icons.check_circle
              : status == 'Active'
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          size: 18,
          color: statusColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}

class _AlertInfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _AlertInfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
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
