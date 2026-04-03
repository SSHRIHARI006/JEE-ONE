import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';

class HospitalListScreen extends StatelessWidget {
  const HospitalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      bottomNavigationBar: const _BottomNavBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandBar(onBack: () => context.go('/triage-result')),
          const SizedBox(height: 18),

          AppPageHeader(
            eyebrow: 'Recommendation',
            title: 'Best hospital options',
            subtitle: 'Choose the fastest safe facility for the patient.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    size: 18,
                    color: AppColors.success,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'READY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_on, color: AppColors.info, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Electronic City, Bangalore',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Top Matches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _HospitalCard(
            tag: 'TOP PICK',
            tagColor: AppColors.primary,
            name: 'St. Mary’s General',
            eta: '8 min',
            distance: '2.4 km',
            riskLabel: 'Low Risk',
            riskBg: AppColors.successSoft,
            riskColor: AppColors.success,
            load: '42%',
            delay: '2 min',
            resources: const ['ICU', 'Ventilator', 'Cardiologist'],
            buttonLabel: 'Route Here',
            onPressed: () => context.go('/navigation'),
          ),

          const SizedBox(height: 12),

          _HospitalCard(
            tag: 'FASTEST',
            tagColor: AppColors.info,
            name: 'Apollo Life Care',
            eta: '3 min',
            distance: '0.8 km',
            riskLabel: 'Medium Risk',
            riskBg: AppColors.warningSoft,
            riskColor: AppColors.warning,
            load: '78%',
            delay: '12 min',
            resources: const ['ICU', 'Ventilator'],
            buttonLabel: 'Select',
            onPressed: () => context.go('/navigation'),
          ),

          const SizedBox(height: 12),

          _HospitalCard(
            tag: 'SAFEST',
            tagColor: AppColors.textPrimary,
            name: 'Fortis Specialty',
            eta: '14 min',
            distance: '4.5 km',
            riskLabel: 'Low Risk',
            riskBg: AppColors.successSoft,
            riskColor: AppColors.success,
            load: '15%',
            delay: '1 min',
            resources: const ['ICU', 'Ventilator', 'Multi-Specialty'],
            buttonLabel: 'Select',
            onPressed: () => context.go('/navigation'),
          ),

          const SizedBox(height: 24),

          const Text(
            'Nearby Ambulance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Container(
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
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.emergency, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit ALS-22',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Advanced Life Support • 4 mins away',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(onPressed: null, child: Text('Assigned')),
              ],
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

class _HospitalCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final String name;
  final String eta;
  final String distance;
  final String riskLabel;
  final Color riskBg;
  final Color riskColor;
  final String load;
  final String delay;
  final List<String> resources;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _HospitalCard({
    required this.tag,
    required this.tagColor,
    required this.name,
    required this.eta,
    required this.distance,
    required this.riskLabel,
    required this.riskBg,
    required this.riskColor,
    required this.load,
    required this.delay,
    required this.resources,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: riskBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  riskLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$distance • ETA $eta',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 340;

              if (stack) {
                return Column(
                  children: [
                    _MiniInfo(label: 'Load', value: load),
                    const SizedBox(height: 10),
                    _MiniInfo(label: 'Delay', value: delay),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _MiniInfo(label: 'Load', value: load),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniInfo(label: 'Delay', value: delay),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resources.map((resource) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  resource,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: tag == 'TOP PICK'
                    ? AppColors.primary
                    : AppColors.textPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
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
