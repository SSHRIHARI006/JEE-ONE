import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/primary_action_button.dart';

class PublicResultScreen extends StatelessWidget {
  final Object? routeExtra;
  const PublicResultScreen({super.key, this.routeExtra});

  static Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : {};

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> payload = _asMap(routeExtra);

    final Map<String, dynamic> data = _asMap(payload['result']);

    final String emergencyType =
        payload['emergency_type']?.toString() ?? 'Other';
    final bool conscious = payload['conscious'] as bool? ?? true;
    final bool breathing = payload['breathing'] as bool? ?? true;
    final bool bleeding = payload['bleeding'] as bool? ?? false;

    final Map<String, dynamic> triage = _asMap(data['triage']);
    final Map<String, dynamic> advice = _asMap(data['advice']);
    final Map<String, dynamic>? ambulance =
        data['ambulance'] is Map ? _asMap(data['ambulance']) : null;

    final int severity = (triage['severity'] as num?)?.toInt() ?? 0;
    final String urgency =
        triage['urgency']?.toString().toUpperCase() ?? 'UNKNOWN';
    final int timeToCritical =
        (triage['time_to_critical_minutes'] as num?)?.toInt() ?? 0;

    final String adviceMessage = advice['message']?.toString().isNotEmpty == true
        ? advice['message'].toString()
        : advice['action']?.toString().isNotEmpty == true
            ? advice['action'].toString()
            : 'Keep the patient calm and still. Help is on the way.';

    final List<_FirstAidStep> steps = _resolveSteps(
      data: data.isEmpty ? null : data,
      emergencyType: emergencyType,
      conscious: conscious,
      breathing: breathing,
      bleeding: bleeding,
      urgency: urgency,
    );

    return AppShellScaffold(
      bottomNavigationBar: const _BottomNavBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandBar(onBack: () => context.go('/')),
          const SizedBox(height: 18),

          AppPageHeader(
            eyebrow: 'First Aid',
            title: 'What to do now',
            subtitle: 'Follow these steps until the ambulance arrives.',
            showBack: false,
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _urgencyBg(urgency),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    severity.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _urgencyColor(urgency),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RISK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _urgencyColor(urgency),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // AI status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _urgencyBg(urgency),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _urgencyColor(urgency).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emergency_rounded,
                  color: _urgencyColor(urgency),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _urgencyColor(urgency),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              urgency,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (timeToCritical > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Critical in ~$timeToCritical min',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _urgencyColor(urgency),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        adviceMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (ambulance != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_taxi_rounded,
                      color: AppColors.success, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ambulance dispatched — ETA ${ambulance['eta_to_patient'] ?? '?'} min',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          Text(
            'First Aid Steps — $emergencyType',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ...steps.asMap().entries.map((entry) {
            final int idx = entry.key;
            final _FirstAidStep step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StepCard(
                stepNumber: idx + 1,
                title: step.title,
                description: step.description,
                icon: step.icon,
                priority: step.priority,
              ),
            );
          }),

          const SizedBox(height: 24),

          PrimaryActionButton(
            label: 'View Hospital Recommendation',
            icon: Icons.local_hospital_outlined,
            onPressed: () => context.go('/hospital-list', extra: data),
          ),
        ],
      ),
    );
  }

  static List<_FirstAidStep> _resolveSteps({
    required Map<String, dynamic>? data,
    required String emergencyType,
    required bool conscious,
    required bool breathing,
    required bool bleeding,
    required String urgency,
  }) {
    final apiSteps = data?['first_aid'];
    if (apiSteps is List && apiSteps.isNotEmpty) {
      final mapped = apiSteps
          .whereType<Map>()
          .map((s) {
            final raw = s['priority']?.toString() ?? 'normal';
            final priority = raw == 'critical'
                ? _Priority.critical
                : raw == 'high'
                    ? _Priority.high
                    : _Priority.normal;
            final icon = priority == _Priority.critical
                ? Icons.warning_rounded
                : priority == _Priority.high
                    ? Icons.healing_rounded
                    : Icons.info_outline_rounded;
            return _FirstAidStep(
              title: s['title']?.toString() ?? '',
              description: s['description']?.toString() ?? '',
              icon: icon,
              priority: priority,
            );
          })
          .where((s) => s.title.isNotEmpty)
          .toList();
      if (mapped.isNotEmpty) return mapped;
    }
    return _buildSteps(
      emergencyType,
      conscious: conscious,
      breathing: breathing,
      bleeding: bleeding,
      urgency: urgency,
    );
  }

  static List<_FirstAidStep> _buildSteps(
    String emergencyType, {
    required bool conscious,
    required bool breathing,
    required bool bleeding,
    required String urgency,
  }) {
    final steps = <_FirstAidStep>[];

    // Universal first steps
    steps.add(const _FirstAidStep(
      title: 'Call 112 immediately',
      description: 'If you have not already called emergency services, call 112 now and keep the line open.',
      icon: Icons.phone_in_talk_rounded,
      priority: _Priority.critical,
    ));

    if (!conscious) {
      steps.add(const _FirstAidStep(
        title: 'Check responsiveness',
        description: 'Tap the patient\'s shoulders firmly and shout "Are you okay?". If no response, tilt head back gently to open the airway.',
        icon: Icons.record_voice_over_rounded,
        priority: _Priority.critical,
      ));
    }

    if (!breathing) {
      steps.add(const _FirstAidStep(
        title: 'Start CPR',
        description: 'Place heel of your hand on the centre of the chest. Push down 5–6 cm, 30 times fast. Then give 2 rescue breaths (pinch nose, seal mouth, blow until chest rises). Repeat until help arrives.',
        icon: Icons.favorite_rounded,
        priority: _Priority.critical,
      ));
    }

    if (bleeding) {
      steps.add(const _FirstAidStep(
        title: 'Control the bleeding',
        description: 'Press a clean cloth firmly on the wound. Do NOT remove it — add more cloth on top if it soaks through. Keep pressing hard for at least 10 minutes without letting go.',
        icon: Icons.healing_rounded,
        priority: _Priority.high,
      ));
    }

    // Emergency-type specific steps
    switch (emergencyType) {
      case 'Cardiac':
        steps.addAll([
          const _FirstAidStep(
            title: 'Start CPR if not breathing',
            description: '30 chest compressions (push hard and fast, 100–120 per minute) followed by 2 rescue breaths. Continue until the ambulance arrives or AED is available.',
            icon: Icons.monitor_heart_rounded,
            priority: _Priority.critical,
          ),
          const _FirstAidStep(
            title: 'Use AED if nearby',
            description: 'If an Automated External Defibrillator is available, turn it on and follow its spoken instructions exactly.',
            icon: Icons.bolt_rounded,
            priority: _Priority.high,
          ),
          const _FirstAidStep(
            title: 'Do not give food or water',
            description: 'Keep the patient still. Loosen tight clothing around the neck and chest. Do not give anything to eat or drink.',
            icon: Icons.no_food_rounded,
            priority: _Priority.normal,
          ),
        ]);
        break;

      case 'Stroke':
        steps.addAll([
          const _FirstAidStep(
            title: 'Do the FAST check',
            description: 'Face drooping? Arm weakness? Speech slurred? Time to call 112. Note the exact time symptoms started — tell the doctors.',
            icon: Icons.psychology_alt_rounded,
            priority: _Priority.critical,
          ),
          const _FirstAidStep(
            title: 'Lay the person down safely',
            description: 'Help them lie down with their head and shoulders slightly raised. Turn them on their side if they vomit. Do not give aspirin or water.',
            icon: Icons.airline_seat_flat_rounded,
            priority: _Priority.high,
          ),
          const _FirstAidStep(
            title: 'Keep them calm and still',
            description: 'Reassure the person. Do not let them eat, drink, or take medication. Stay with them and note any changes.',
            icon: Icons.self_improvement_rounded,
            priority: _Priority.normal,
          ),
        ]);
        break;

      case 'Accident':
        steps.addAll([
          const _FirstAidStep(
            title: 'Do not move the person',
            description: 'Unless they are in immediate danger (e.g. fire), do not move them. A spinal injury can worsen with movement.',
            icon: Icons.warning_rounded,
            priority: _Priority.critical,
          ),
          const _FirstAidStep(
            title: 'Keep them warm and still',
            description: 'Cover with a jacket or blanket to prevent shock. Talk to them calmly to keep them conscious.',
            icon: Icons.thermostat_rounded,
            priority: _Priority.high,
          ),
          const _FirstAidStep(
            title: 'Do not remove embedded objects',
            description: 'If something is stuck in the body, do not pull it out. Apply pressure around it, not on it.',
            icon: Icons.healing_rounded,
            priority: _Priority.high,
          ),
        ]);
        break;

      case 'Burn':
        steps.addAll([
          const _FirstAidStep(
            title: 'Cool the burn immediately',
            description: 'Run cool (not cold or icy) water over the burn for at least 10–20 minutes. Do not use ice, butter, or toothpaste.',
            icon: Icons.water_drop_rounded,
            priority: _Priority.critical,
          ),
          const _FirstAidStep(
            title: 'Cover loosely',
            description: 'Once cooled, cover with a clean non-fluffy material like cling film or a clean plastic bag. Do not use cotton wool or fluffy bandages.',
            icon: Icons.layers_rounded,
            priority: _Priority.high,
          ),
          const _FirstAidStep(
            title: 'Do not burst blisters',
            description: 'Remove watches and jewellery near the burn (swelling may occur). Do not pop any blisters — this increases infection risk.',
            icon: Icons.block_rounded,
            priority: _Priority.normal,
          ),
        ]);
        break;

      case 'Breathing':
        steps.addAll([
          const _FirstAidStep(
            title: 'Sit the person upright',
            description: 'Help them sit up straight or lean slightly forward. Do not lay them flat — this makes breathing harder.',
            icon: Icons.airline_seat_recline_extra_rounded,
            priority: _Priority.critical,
          ),
          const _FirstAidStep(
            title: 'Loosen tight clothing',
            description: 'Loosen anything tight around the neck, chest, or waist. Unbutton the top button of their shirt.',
            icon: Icons.checkroom_rounded,
            priority: _Priority.high,
          ),
          const _FirstAidStep(
            title: 'Use their inhaler if available',
            description: 'If they have an asthma inhaler, help them use it. For severe wheezing, up to 10 puffs every 10–20 minutes while waiting for help.',
            icon: Icons.air_rounded,
            priority: _Priority.high,
          ),
        ]);
        break;

      default: // Other
        steps.addAll([
          const _FirstAidStep(
            title: 'Keep the person calm and still',
            description: 'Reassure them that help is on the way. Reduce their movement and help them find a comfortable position.',
            icon: Icons.self_improvement_rounded,
            priority: _Priority.high,
          ),
          const _FirstAidStep(
            title: 'Do not give food or drink',
            description: 'Until medical help arrives, do not give the person anything to eat or drink in case surgery is needed.',
            icon: Icons.no_food_rounded,
            priority: _Priority.normal,
          ),
        ]);
    }

    return steps;
  }

  static Color _urgencyBg(String urgency) {
    switch (urgency) {
      case 'CRITICAL':
        return AppColors.dangerSoft;
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
    switch (urgency) {
      case 'CRITICAL':
        return AppColors.primary;
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

enum _Priority { critical, high, normal }

class _FirstAidStep {
  final String title;
  final String description;
  final IconData icon;
  final _Priority priority;

  const _FirstAidStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
  });
}

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final _Priority priority;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color bgColor;
    switch (priority) {
      case _Priority.critical:
        color = AppColors.primary;
        bgColor = AppColors.dangerSoft;
        break;
      case _Priority.high:
        color = AppColors.warning;
        bgColor = AppColors.warningSoft;
        break;
      case _Priority.normal:
        color = AppColors.info;
        bgColor = AppColors.infoSoft;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    height: 16,
                    width: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
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

  const _NavItem({
    required this.icon,
    required this.label,
  });

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
