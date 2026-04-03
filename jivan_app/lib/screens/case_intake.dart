import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/primary_action_button.dart';

class CaseIntakeScreen extends StatefulWidget {
  const CaseIntakeScreen({super.key});

  @override
  State<CaseIntakeScreen> createState() => _CaseIntakeScreenState();
}

class _CaseIntakeScreenState extends State<CaseIntakeScreen> {
  final TextEditingController spo2Controller = TextEditingController(
    text: '94',
  );
  final TextEditingController systolicController = TextEditingController(
    text: '175',
  );
  final TextEditingController diastolicController = TextEditingController(
    text: '105',
  );

  bool voiceMode = true;
  bool conscious = true;
  bool breathing = true;
  bool bleeding = true;
  bool isSubmitting = false;

  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isListening = false;
  String _spokenText = 'Tap the mic and speak patient symptoms...';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords.isEmpty
              ? 'Listening...'
              : result.recognizedWords;
        });
      },
    );

    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _submitCase() async {
    try {
      setState(() {
        isSubmitting = true;
      });

      final result = await ApiService.submitSosCase(
        patientId: 'PATIENT-882',
        inputText: _spokenText == 'Tap the mic and speak patient symptoms...'
            ? 'Severe dizziness, vomiting, can\'t walk straight'
            : _spokenText,
        spo2: int.tryParse(spo2Controller.text) ?? 94,
        systolicBp: int.tryParse(systolicController.text) ?? 175,
        diastolicBp: int.tryParse(diastolicController.text) ?? 105,
        latitude: 18.521,
        longitude: 73.812,
      );

      if (!mounted) return;

      context.go('/triage-result', extra: result);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    spo2Controller.dispose();
    systolicController.dispose();
    diastolicController.dispose();
    super.dispose();
  }

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
            eyebrow: 'Ambulance',
            title: 'Case intake',
            subtitle: 'Enter symptoms and vitals for AI triage.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emergency, size: 18, color: AppColors.warning),
                  SizedBox(height: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  title: 'Voice Input',
                  icon: Icons.mic,
                  active: voiceMode,
                  color: AppColors.primary,
                  onTap: () => setState(() => voiceMode = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeButton(
                  title: 'Manual Input',
                  icon: Icons.keyboard_alt_outlined,
                  active: !voiceMode,
                  color: AppColors.info,
                  onTap: () => setState(() => voiceMode = false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (voiceMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: _isListening ? _stopListening : _startListening,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _isListening
                              ? 'Listening for voice intake...'
                              : 'Tap mic to start voice input',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _spokenText,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (voiceMode) const SizedBox(height: 22),

          const Text(
            'Vitals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _VitalField(
                  label: 'SpO2',
                  suffix: '%',
                  controller: spo2Controller,
                  icon: Icons.air,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VitalField(
                  label: 'Systolic BP',
                  suffix: 'mmHg',
                  controller: systolicController,
                  icon: Icons.monitor_heart_outlined,
                  iconColor: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _VitalField(
            label: 'Diastolic BP',
            suffix: 'mmHg',
            controller: diastolicController,
            icon: Icons.monitor_heart_outlined,
            iconColor: AppColors.primary,
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
            onChanged: (v) => setState(() => conscious = v),
            activeColor: AppColors.info,
          ),
          const SizedBox(height: 10),
          _ConditionTile(
            title: 'Breathing',
            value: breathing,
            onChanged: (v) => setState(() => breathing = v),
            activeColor: AppColors.success,
          ),
          const SizedBox(height: 10),
          _ConditionTile(
            title: 'Bleeding',
            value: bleeding,
            onChanged: (v) => setState(() => bleeding = v),
            activeColor: AppColors.primary,
          ),

          const SizedBox(height: 26),

          PrimaryActionButton(
            label: isSubmitting ? 'Submitting...' : 'Run AI Triage',
            icon: Icons.arrow_forward,
            onPressed: isSubmitting ? null : _submitCase,
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

class _ModeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.icon,
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
        height: 54,
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalField extends StatelessWidget {
  final String label;
  final String suffix;
  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;

  const _VitalField({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.icon,
    required this.iconColor,
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
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              suffixText: suffix,
              suffixStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
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
        color: value ? activeColor.withOpacity(0.10) : AppColors.surface,
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
          Switch(value: value, onChanged: onChanged, activeColor: activeColor),
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
