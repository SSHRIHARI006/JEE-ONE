import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';

class TriageLoadingScreen extends StatefulWidget {
  const TriageLoadingScreen({super.key});

  @override
  State<TriageLoadingScreen> createState() => _TriageLoadingScreenState();
}

class _TriageLoadingScreenState extends State<TriageLoadingScreen> {
  double progress = 0.0;
  int currentStep = 0;
  Timer? _timer;

  final List<String> steps = [
    'Reading patient data',
    'Checking severity',
    'Matching hospital resources',
    'Preparing recommendation',
  ];

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  void _startProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 850), (timer) {
      if (!mounted) return;

      if (progress < 1.0) {
        setState(() {
          progress += 0.25;
          if (currentStep < steps.length - 1) {
            currentStep++;
          }
        });
      } else {
        _timer?.cancel();
        context.go('/triage-result');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int percentage = (progress * 100).clamp(0, 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'AI Triage Running',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please wait while Jeevan evaluates the case.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      height: 150,
                      width: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor: AppColors.dangerSoft,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$percentage%',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'PROCESSING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bolt,
                            size: 18,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              steps[currentStep],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
