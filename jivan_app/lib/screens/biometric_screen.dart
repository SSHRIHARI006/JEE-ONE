import 'package:flutter/material.dart';

class BiometricScreen extends StatelessWidget {
  const BiometricScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFD11111);
    const Color darkText = Color(0xFF111111);
    const Color mutedText = Color(0xFF5F3A3A);
    const Color softBg = Color(0xFFF7F3F3);
    const Color cardBg = Color(0xFFFFFFFF);
    const Color lightGray = Color(0xFFF1F1F1);
    const Color blueCard = Color(0xFF0D84A5);
    const Color paleRed = Color(0xFFFFE5E5);

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
              const SizedBox(height: 34),

              const Text(
                'Patient Identity',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Securely identify the patient using clinical biometrics to retrieve medical history.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF5F3A3A),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'BIOMETRIC 01',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w700,
                            color: primaryRed,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE1E1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_user,
                                size: 16,
                                color: Color(0xFF261717),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'HIGH PRECISION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF261717),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Face Scan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      height: 270,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6F6F6F),
                            Color(0xFF595959),
                            Color(0xFF4C4C4C),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _FaceGridPainter()),
                          ),
                          const Positioned.fill(
                            child: Center(
                              child: Icon(
                                Icons.account_circle,
                                size: 170,
                                color: Color(0xFFBEBEBE),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _FaceScanFramePainter(),
                            ),
                          ),
                          const Positioned(
                            top: 122,
                            left: 118,
                            child: _RedDot(),
                          ),
                          const Positioned(
                            top: 122,
                            right: 118,
                            child: _RedDot(),
                          ),
                          const Positioned(
                            top: 150,
                            left: 0,
                            right: 0,
                            child: Center(child: _RedDot()),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(
                          Icons.face_retouching_natural,
                          size: 24,
                        ),
                        label: const Text(
                          'Initialize Face Scan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BIOMETRIC 02',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4E3B3B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fingerprint ID',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: Container(
                        height: 128,
                        width: 128,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.fingerprint,
                            color: primaryRed,
                            size: 58,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Place patient thumb on the scanner area',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF5F3A3A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 140,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            color: primaryRed,
                            size: 28,
                          ),
                          Spacer(),
                          Text(
                            'Unknown Patient',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'SKIP BIOMETRICS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      height: 140,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: blueCard,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          Spacer(),
                          Text(
                            'TEMP ID',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD7F4FF),
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'J-9402',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F7),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFCFCF)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: primaryRed,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Biometric verification speeds up triage by 4.2 minutes on average. If patient is unconscious, use "Unknown Patient".',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: primaryRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
    return Row(
      children: [
        const Text(
          '✱',
          style: TextStyle(
            color: Color(0xFFD11111),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Jeevan',
          style: TextStyle(
            color: Color(0xFFD11111),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          height: 34,
          width: 34,
          decoration: const BoxDecoration(
            color: Color(0xFF5A3C3C),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.question_mark, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

class _RedDot extends StatelessWidget {
  const _RedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: 12,
      decoration: const BoxDecoration(
        color: Color(0xFFD11111),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FaceGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final Paint glowPaint = Paint()
      ..shader =
          const RadialGradient(
            colors: [Colors.white54, Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.23),
              radius: 80,
            ),
          );

    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.23),
      80,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FaceScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const Color frameColor = Color(0xFFD11111);
    final Paint paint = Paint()
      ..color = frameColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double pad = 40;
    const double corner = 34;

    final Rect rect = Rect.fromLTWH(
      pad,
      52,
      size.width - (pad * 2),
      size.height - 104,
    );

    canvas.drawLine(
      Offset(rect.left, rect.top + corner),
      Offset(rect.left, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + corner, rect.top),
      paint,
    );

    canvas.drawLine(
      Offset(rect.right - corner, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + corner),
      paint,
    );

    canvas.drawLine(
      Offset(rect.left, rect.bottom - corner),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + corner, rect.bottom),
      paint,
    );

    canvas.drawLine(
      Offset(rect.right - corner, rect.bottom),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - corner),
      Offset(rect.right, rect.bottom),
      paint,
    );

    final Paint centerLinePaint = Paint()
      ..color = frameColor
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(0, size.height * 0.52),
      Offset(size.width, size.height * 0.52),
      centerLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
