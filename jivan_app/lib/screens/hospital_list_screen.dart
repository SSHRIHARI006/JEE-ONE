import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';

// ---------------------------------------------------------------------------
// Compatibility → risk label/colours
// ---------------------------------------------------------------------------
_RiskStyle _riskStyle(String compatibility) {
  switch (compatibility.toUpperCase()) {
    case 'FULL':
      return const _RiskStyle('Low Risk', AppColors.successSoft, AppColors.success);
    case 'PARTIAL':
      return const _RiskStyle('Medium Risk', AppColors.warningSoft, AppColors.warning);
    default:
      return const _RiskStyle('High Risk', AppColors.dangerSoft, AppColors.primary);
  }
}

class _RiskStyle {
  final String label;
  final Color bg;
  final Color fg;
  const _RiskStyle(this.label, this.bg, this.fg);
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------
class HospitalListScreen extends StatelessWidget {
  const HospitalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final Map<String, dynamic>? data =
        extra is Map<String, dynamic> ? extra : null;

    // Primary recommendation
    final routing = data?['routing'] as Map<String, dynamic>?;
    // Alternative recommendations
    final rawAlts = data?['alternatives'] as List<dynamic>? ?? [];
    final alternatives = rawAlts.cast<Map<String, dynamic>>();
    // Ambulance assignment
    final ambulance = data?['ambulance'] as Map<String, dynamic>?;
    // Build the ordered list: top pick first, then alternatives
    final List<_HospitalEntry> entries = [];
    if (routing != null) {
      entries.add(_HospitalEntry(
        tag: 'TOP PICK',
        tagColor: AppColors.primary,
        data: routing,
      ));
    }
    for (int i = 0; i < alternatives.length; i++) {
      entries.add(_HospitalEntry(
        tag: i == 0 ? 'FASTEST' : 'SAFEST',
        tagColor: i == 0 ? AppColors.info : AppColors.textPrimary,
        data: alternatives[i],
      ));
    }

    return AppShellScaffold(
      bottomNavigationBar: const _BottomNavBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandBar(
            onBack: () => context.go('/triage-result', extra: data),
            onMap: () => context.go('/mapbox', extra: data),
          ),
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
                  Icon(Icons.health_and_safety_outlined,
                      size: 18, color: AppColors.success),
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

          // Location chip — uses top hospital name as reference point
          if (routing != null)
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
                  const Icon(Icons.location_on, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      routing['name'] as String? ?? 'Nearest hospital',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${routing['distance_km']} km',
                    style: const TextStyle(
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

          if (entries.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hospital recommendations available.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HospitalCard(
                    tag: entry.tag,
                    tagColor: entry.tagColor,
                    hospitalData: entry.data,
                    isTopPick: entry.tag == 'TOP PICK',
                    onPressed: () => context.go(
                      '/navigation',
                      extra: {
                        'hospital': entry.data,
                        'fullResponse': data,
                      },
                    ),
                  ),
                )),

          const SizedBox(height: 24),

          const Text(
            'Assigned Ambulance',
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ambulance?['id']?.toString() ?? 'Not yet assigned',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ambulance != null
                            ? '${ambulance['status']} • ETA ${ambulance['eta_to_patient']} min'
                            : 'Awaiting dispatch',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: null,
                  child: Text(
                    ambulance != null ? 'Assigned' : 'Pending',
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

class _HospitalEntry {
  final String tag;
  final Color tagColor;
  final Map<String, dynamic> data;
  const _HospitalEntry({required this.tag, required this.tagColor, required this.data});
}

// ---------------------------------------------------------------------------
// Hospital card — driven entirely by API data
// ---------------------------------------------------------------------------
class _HospitalCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final Map<String, dynamic> hospitalData;
  final bool isTopPick;
  final VoidCallback onPressed;

  const _HospitalCard({
    required this.tag,
    required this.tagColor,
    required this.hospitalData,
    required this.isTopPick,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String name = hospitalData['name']?.toString() ?? 'Unknown Hospital';
    final int eta = (hospitalData['eta'] as num?)?.toInt() ?? 0;
    final double distKm =
        (hospitalData['distance_km'] as num?)?.toDouble() ?? 0.0;
    final String compatibility =
        hospitalData['compatibility']?.toString() ?? 'RISKY';
    final double score =
        (hospitalData['score'] as num?)?.toDouble() ?? 0.0;
    final double load =
        (hospitalData['load_percentage'] as num?)?.toDouble() ?? 0.0;
    final int delay =
        (hospitalData['intake_delay'] as num?)?.toInt() ?? 0;

    // Pros as resource chips; fall back to explanation if no pros
    final rawPros = hospitalData['pros'] as List<dynamic>?;
    final List<String> resources = rawPros != null && rawPros.isNotEmpty
        ? rawPros.cast<String>()
        : [hospitalData['explanation']?.toString() ?? compatibility];

    final risk = _riskStyle(compatibility);

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
              _Pill(label: tag, bg: tagColor.withAlpha(25), fg: tagColor),
              _Pill(label: risk.label, bg: risk.bg, fg: risk.fg),
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
            '${distKm.toStringAsFixed(1)} km  •  ETA $eta min  •  Score ${score.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (ctx, constraints) {
            final bool stack = constraints.maxWidth < 340;
            if (stack) {
              return Column(children: [
                _MiniInfo(label: 'Load', value: '${load.toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                _MiniInfo(label: 'Delay', value: '$delay min'),
              ]);
            }
            return Row(children: [
              Expanded(
                  child: _MiniInfo(
                      label: 'Load', value: '${load.toStringAsFixed(0)}%')),
              const SizedBox(width: 10),
              Expanded(child: _MiniInfo(label: 'Delay', value: '$delay min')),
            ]);
          }),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resources.take(4).map((r) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(r,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
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
                backgroundColor:
                    isTopPick ? AppColors.primary : AppColors.textPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isTopPick ? 'Route Here' : 'Select',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
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
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared shell widgets
// ---------------------------------------------------------------------------
class _BrandBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onMap;
  const _BrandBar({required this.onBack, this.onMap});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      InkWell(
        onTap: onBack,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
        ),
      ),
      const SizedBox(width: 12),
      const Text('Jeevan',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary)),
      const Spacer(),
      if (onMap != null)
        InkWell(
          onTap: onMap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: const Icon(Icons.map_outlined,
                size: 20, color: AppColors.primary),
          ),
        ),
    ]);
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
          border: Border(top: BorderSide(color: AppColors.border))),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_filled, label: 'Home'),
          _NavItem(icon: Icons.history, label: 'History'),
          _NavItem(
              icon: Icons.local_hospital_outlined,
              label: 'Hospitals',
              active: true),
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

  const _NavItem(
      {required this.icon, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: active ? AppColors.dangerSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 20,
            color: active ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primary : AppColors.textSecondary)),
      ]),
    );
  }
}
