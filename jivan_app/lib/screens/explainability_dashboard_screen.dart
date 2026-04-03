import 'package:flutter/material.dart';

class ExplainabilityDashboardScreen extends StatelessWidget {
  const ExplainabilityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFD11111);
    const Color darkText = Color(0xFF111111);
    const Color mutedText = Color(0xFF5F5F5F);
    const Color softCard = Color(0xFFF7F7F7);
    const Color paleRed = Color(0xFFFFEEEE);
    const Color softBlue = Color(0xFFEFF6FF);
    const Color softGray = Color(0xFFF3F3F3);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const _BottomNavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopBar(),
              const SizedBox(height: 28),

              const Text(
                'ACTIVE INCIDENT #492-B',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7A7A7A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Medical\nIntelligence\nDashboard',
                style: TextStyle(
                  fontSize: 26,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Real-time explainability data for AI-assisted triage and hospital routing decisions.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: const Border(
                    bottom: BorderSide(color: primaryRed, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.monitor_heart_outlined,
                          color: primaryRed,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AI Severity Score',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        height: 170,
                        width: 170,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 170,
                              width: 170,
                              child: CircularProgressIndicator(
                                value: 0.82,
                                strokeWidth: 8,
                                backgroundColor: Color(0xFFF1D7D7),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryRed,
                                ),
                              ),
                            ),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '8.2',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w700,
                                    color: darkText,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'CRITICAL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4A4A4A),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Confidence Interval',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '94.2%',
                          style: TextStyle(
                            fontSize: 12,
                            color: darkText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: const LinearProgressIndicator(
                        minHeight: 6,
                        value: 0.942,
                        backgroundColor: Color(0xFFE6EEF8),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0D84A5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: primaryRed,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Decision Logic &\nExplanation',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        color: softGray,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: primaryRed, width: 3),
                          ),
                        ),
                        child: const Text(
                          '"AI analysis of reported symptoms — sudden onset chest pain radiating to left arm, tachycardia (112bpm), and diaphoresis — indicates a 92% probability of acute myocardial infarction. Nearest specialized cardiac facility is recommended over general trauma centers due to cure intervention times."',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.75,
                            color: Color(0xFF444444),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SignalCard(
                      icon: Icons.priority_high,
                      title: 'PRIMARY DRIVER',
                      value: 'Radiating Thoracic Pain',
                      iconColor: primaryRed,
                    ),
                    const SizedBox(height: 10),
                    const _SignalCard(
                      icon: Icons.health_and_safety_outlined,
                      title: 'SECONDARY SIGNAL',
                      value: 'Patient History (Hypertension)',
                      iconColor: Color(0xFF0D84A5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.local_hospital_outlined,
                          color: primaryRed,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hospital\nRanking\nLogic',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                              height: 1.25,
                            ),
                          ),
                        ),
                        _Tag(text: 'DISTANCE'),
                        SizedBox(width: 6),
                        _Tag(text: 'SPECIALTY'),
                        SizedBox(width: 6),
                        _Tag(text: 'WAIT TIME', filled: true),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _HospitalRankItem(
                      rank: '1',
                      name: 'City Cardiac Center',
                      distance: '2.4 km',
                      wait: '4m Wait',
                      tag: 'Recommended',
                      tagColor: primaryRed,
                      meta: 'Level 1 Cardiac',
                      highlighted: true,
                    ),
                    const SizedBox(height: 12),
                    const _HospitalRankItem(
                      rank: '2',
                      name: 'Metropolitan General',
                      distance: '1.1 km',
                      wait: '22m Wait',
                      tag: 'Alternative',
                      tagColor: Color(0xFF8A8A8A),
                      meta: 'High Load',
                    ),
                    const SizedBox(height: 12),
                    const _HospitalRankItem(
                      rank: '3',
                      name: 'St. Jude Emergency',
                      distance: '4.8 km',
                      wait: '45m Wait',
                      tag: 'Capacity Full',
                      tagColor: Color(0xFFB5B5B5),
                      meta: '',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Row(
                children: [
                  Expanded(
                    child: _VitalCard(
                      icon: Icons.show_chart,
                      value: '112',
                      label: 'BPM PULSE',
                      iconColor: primaryRed,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: _VitalCard(
                      icon: Icons.air,
                      value: '96%',
                      label: 'SPO2 LEVEL',
                      iconColor: Color(0xFF0D84A5),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFCFCF)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: primaryRed),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Protocol Deviation Alert\nAI bypassed Metropolitan General (Nearest) due to surge ER admission times. Efficiency gain: +18 minutes.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFFC24A4A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insights_outlined, color: primaryRed),
                        SizedBox(width: 8),
                        Text(
                          'Route Stability Analysis',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _BarChartSection(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: _StatText(
                            title: 'MODEL\nDRIFT',
                            value: 'Minimal\n(0.02)',
                          ),
                        ),
                        const Expanded(
                          child: _StatText(title: 'LATENCY', value: '24ms'),
                        ),
                        Expanded(
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: primaryRed,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Export\nCase\nStudy',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFD11111);

    return Row(
      children: [
        const Text(
          '✱',
          style: TextStyle(
            color: primaryRed,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Jeevan',
          style: TextStyle(
            color: primaryRed,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, color: Color(0xFF333333), size: 20),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none,
            color: Color(0xFF333333),
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _SignalCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
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

class _Tag extends StatelessWidget {
  final String text;
  final bool filled;

  const _Tag({required this.text, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFD11111) : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : const Color(0xFF555555),
        ),
      ),
    );
  }
}

class _HospitalRankItem extends StatelessWidget {
  final String rank;
  final String name;
  final String distance;
  final String wait;
  final String tag;
  final Color tagColor;
  final String meta;
  final bool highlighted;

  const _HospitalRankItem({
    required this.rank,
    required this.name,
    required this.distance,
    required this.wait,
    required this.tag,
    required this.tagColor,
    required this.meta,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF7F7) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: highlighted
                  ? const Color(0xFFD11111)
                  : const Color(0xFFE9E9E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                rank,
                style: TextStyle(
                  color: highlighted ? Colors.white : const Color(0xFF555555),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                if (tag.isNotEmpty)
                  Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tagColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$distance  •  $wait',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _VitalCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartSection extends StatelessWidget {
  const _BarChartSection();

  @override
  Widget build(BuildContext context) {
    final bars = [
      42.0,
      72.0,
      36.0,
      88.0,
      54.0,
      67.0,
      41.0,
      58.0,
      92.0,
      63.0,
      74.0,
      28.0,
    ];

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (index) {
          final isRed = index == 3 || index == 8;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                height: bars[index],
                decoration: BoxDecoration(
                  color: isRed
                      ? const Color(0xFFD11111)
                      : const Color(0xFFE8B5B5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatText extends StatelessWidget {
  final String title;
  final String value;

  const _StatText({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              height: 1.4,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
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
      height: 84,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_filled, label: 'Home'),
          _NavItem(icon: Icons.history, label: 'History'),
          _NavItem(icon: Icons.local_hospital, label: 'Hospitals'),
          _NavItem(icon: Icons.person, label: 'Profile', active: true),
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
    const Color activeBg = Color(0xFFFFEFEF);
    const Color activeColor = Color(0xFFD11111);
    const Color muted = Color(0xFF667085);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: active ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? activeColor : muted, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? activeColor : muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
