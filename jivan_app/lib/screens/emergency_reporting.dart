import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../services/patient_identity_service.dart';
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

  // Scene photo
  final ImagePicker _picker = ImagePicker();
  XFile? _sceneImage;
  bool _sceneAnalyzed = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _patientId = 'PATIENT-LOCAL';
    _initPatientId();
    _fetchLocation();
  }

  Future<void> _initPatientId() async {
    final id = await PatientIdentityService.getOrCreatePatientId();
    if (!mounted) return;
    setState(() {
      _patientId = id;
    });
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

  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (image != null && mounted) {
      setState(() {
        _sceneImage = image;
        _sceneAnalyzed = true;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (image != null && mounted) {
      setState(() {
        _sceneImage = image;
        _sceneAnalyzed = true;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _sceneImage = null;
      _sceneAnalyzed = false;
    });
  }

  /// Detect MIME type from magic bytes
  String _detectMimeType(List<int> bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  Future<void> _submitCase() async {
    final conditions = <String>[];
    if (conscious) conditions.add('conscious');
    if (breathing) conditions.add('breathing normally');
    if (bleeding) conditions.add('actively bleeding');
    final conditionText =
        conditions.isEmpty ? 'unknown condition' : conditions.join(', ');
    final inputText =
        '$selectedEmergency emergency. Patient is $conditionText. Severity: $selectedSeverity.';

    try {
      setState(() {
        isSubmitting = true;
        _statusMessage = 'Preparing submission...';
      });

      Map<String, dynamic>? sceneContext;

      // Step 1: If scene photo exists, analyze it first
      if (_sceneImage != null) {
        setState(() => _statusMessage = '📸 Analyzing scene photo...');

        final bytes = await _sceneImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        final mediaType = _detectMimeType(bytes);

        try {
          sceneContext = await ApiService.analyzeScene(
            imageBase64: base64Image,
            mediaType: mediaType,
          );
        } catch (e) {
          // Scene analysis is optional — don't block SOS if it fails
          debugPrint('[SCENE] Analysis failed: $e');
        }
      }

      // Step 2: Submit SOS with scene context
      setState(() => _statusMessage = '🚨 Running AI triage...');

      final result = await ApiService.submitSosCase(
        patientId: _patientId,
        inputText: inputText,
        spo2: 94,
        systolicBp: 120,
        diastolicBp: 80,
        latitude: _currentLat,
        longitude: _currentLng,
        sourceType: 'public',
        sceneContext: sceneContext,
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
      if (mounted) {
        setState(() {
          isSubmitting = false;
          _statusMessage = '';
        });
      }
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

              final mild = _SeverityChip(
                label: 'Mild',
                active: selectedSeverity == 'Mild',
                color: AppColors.success,
                onTap: () {
                  setState(() {
                    selectedSeverity = 'Mild';
                  });
                },
              );

              final moderate = _SeverityChip(
                label: 'Moderate',
                active: selectedSeverity == 'Moderate',
                color: AppColors.warning,
                onTap: () {
                  setState(() {
                    selectedSeverity = 'Moderate';
                  });
                },
              );

              final critical = _SeverityChip(
                label: 'Critical',
                active: selectedSeverity == 'Critical',
                color: AppColors.primary,
                onTap: () {
                  setState(() {
                    selectedSeverity = 'Critical';
                  });
                },
              );

              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    mild,
                    const SizedBox(height: 10),
                    moderate,
                    const SizedBox(height: 10),
                    critical,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: mild),
                  const SizedBox(width: 10),
                  Expanded(child: moderate),
                  const SizedBox(width: 10),
                  Expanded(child: critical),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // --- Scene Photo Section (Optional) ---
          const Text(
            'Scene Photo (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'AI will analyze the scene to improve triage accuracy.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          if (_sceneImage == null)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickFromCamera,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.infoSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              color: AppColors.info, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Camera',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickFromGallery,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_rounded,
                              color: AppColors.textSecondary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Gallery',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(
                            _sceneImage!.path,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_sceneImage!.path),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scene photo captured',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'AI will analyze on submit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _removeImage,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 26),

          if (isSubmitting && _statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),

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
