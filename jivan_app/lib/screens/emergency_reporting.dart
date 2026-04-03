import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/primary_action_button.dart';

class EmergencyReportingScreen extends StatefulWidget {
  const EmergencyReportingScreen({super.key});

  @override
  State<EmergencyReportingScreen> createState() =>
      _EmergencyReportingScreenState();
}

class _EmergencyReportingScreenState extends State<EmergencyReportingScreen> {
  String selectedEmergency = 'Accident';
  String selectedSeverity = 'Critical';

  bool conscious = true;
  bool breathing = true;
  bool bleeding = false;
  bool isSubmitting = false;

  late String _patientId;
  double _currentLat = 18.521;
  double _currentLng = 73.812;
  bool _locationFetched = false;

  @override
  void initState() {
    super.initState();
    _patientId = 'PATIENT-${DateTime.now().millisecondsSinceEpoch % 100000}';
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final position = await ApiService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _locationFetched = true;
      });
    }
  }

  Future<void> _submitCase() async {
    final conditions = <String>[];
    if (conscious) conditions.add('conscious');
    if (breathing) conditions.add('breathing normally');
    if (bleeding) conditions.add('actively bleeding');
    final conditionText = conditions.isEmpty ? 'unknown condition' : conditions.join(', ');
    final inputText =
        '$selectedEmergency emergency. Patient is $conditionText. Severity: $selectedSeverity.';

    try {
      setState(() => isSubmitting = true);

      final result = await ApiService.submitSosCase(
        patientId: _patientId,
        inputText: inputText,
        spo2: 94,
        systolicBp: 120,
        diastolicBp: 80,
        latitude: _currentLat,
        longitude: _currentLng,
        sourceType: 'public',
      );

      if (!mounted) return;
      context.go('/public-result', extra: {
        'result': result,
        'emergency_type': selectedEmergency,
        'conscious': conscious,
        'breathing': breathing,
        'bleeding': bleeding,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  final List<String> emergencyTypes = [
    'Accident',
    'Cardiac',
    'Stroke',
    'Burn',
    'Breathing',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      bottomNavigationBar: const _BottomNavBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandBar(onBack: () => context.go('/')),
          const SizedBox(height: 18),

          AppPageHeader(
            eyebrow: 'Report',
            title: 'Emergency intake',
            subtitle: 'Select the incident type and patient condition.',
            showBack: false,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 18, color: AppColors.info),
                  SizedBox(height: 4),
                  Text(
                    'GPS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
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
            child: Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: _locationFetched ? AppColors.success : AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _locationFetched
                        ? '${_currentLat.toStringAsFixed(5)}, ${_currentLng.toStringAsFixed(5)}'
                        : 'Fetching location...',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  _locationFetched ? 'Live' : 'GPS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _locationFetched
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Emergency Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: emergencyTypes.map((type) {
              final isSelected = selectedEmergency == type;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedEmergency = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.dangerSoft
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForType(type),
                        size: 18,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          const Text(
            'Condition',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _ConditionTile(
            title: 'Conscious',
            value: conscious,
            onChanged: (value) {
              setState(() {
                conscious = value;
              });
            },
            activeColor: AppColors.info,
          ),
          const SizedBox(height: 10),
          _ConditionTile(
            title: 'Breathing',
            value: breathing,
            onChanged: (value) {
              setState(() {
                breathing = value;
              });
            },
            activeColor: AppColors.success,
          ),
          const SizedBox(height: 10),
          _ConditionTile(
            title: 'Bleeding',
            value: bleeding,
            onChanged: (value) {
              setState(() {
                bleeding = value;
              });
            },
            activeColor: AppColors.primary,
          ),

          const SizedBox(height: 24),

          const Text(
            'Severity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 360;

              final children = [
                Expanded(
                  child: _SeverityChip(
                    label: 'Mild',
                    active: selectedSeverity == 'Mild',
                    color: AppColors.success,
                    onTap: () {
                      setState(() {
                        selectedSeverity = 'Mild';
                      });
                    },
                  ),
                ),
                if (!stack) const SizedBox(width: 10),
                Expanded(
                  child: _SeverityChip(
                    label: 'Moderate',
                    active: selectedSeverity == 'Moderate',
                    color: AppColors.warning,
                    onTap: () {
                      setState(() {
                        selectedSeverity = 'Moderate';
                      });
                    },
                  ),
                ),
                if (!stack) const SizedBox(width: 10),
                Expanded(
                  child: _SeverityChip(
                    label: 'Critical',
                    active: selectedSeverity == 'Critical',
                    color: AppColors.primary,
                    onTap: () {
                      setState(() {
                        selectedSeverity = 'Critical';
                      });
                    },
                  ),
                ),
              ];

              if (stack) {
                return Column(
                  children: [
                    children[0],
                    const SizedBox(height: 10),
                    children[1],
                    const SizedBox(height: 10),
                    children[2],
                  ],
                );
              }

              return Row(children: children);
            },
          ),

          const SizedBox(height: 26),

          PrimaryActionButton(
            label: isSubmitting ? 'Submitting...' : 'Start AI Triage',
            icon: Icons.arrow_forward,
            onPressed: isSubmitting ? null : _submitCase,
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Accident':
        return Icons.car_crash_outlined;
      case 'Cardiac':
        return Icons.favorite_border;
      case 'Stroke':
        return Icons.psychology_alt_outlined;
      case 'Burn':
        return Icons.local_fire_department_outlined;
      case 'Breathing':
        return Icons.air;
      default:
        return Icons.warning_amber_rounded;
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

class _ConditionTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _ConditionTile({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: value ? activeColor.withValues(alpha: 0.10) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: value ? activeColor : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.radio_button_unchecked,
            color: value ? activeColor : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: activeColor),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _SeverityChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? color : AppColors.textPrimary,
          ),
        ),
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

  const _NavItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
