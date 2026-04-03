import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_reporting.dart';
import 'screens/case_intake.dart';
import 'screens/triage_loading_screen.dart';
import 'screens/triage_result_screen.dart';
import 'screens/hospital_list_screen.dart';
import 'screens/navigation_screen.dart';
import 'screens/handover_screen.dart';
import 'screens/biometric_screen.dart';
import 'screens/explainability_dashboard_screen.dart';

void main() {
  runApp(const JeevanApp());
}

class JeevanApp extends StatelessWidget {
  const JeevanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/emergency-reporting',
          builder: (context, state) => const EmergencyReportingScreen(),
        ),
        GoRoute(
          path: '/case-intake',
          builder: (context, state) => const CaseIntakeScreen(),
        ),
        GoRoute(
          path: '/triage-loading',
          builder: (context, state) => const TriageLoadingScreen(),
        ),
        GoRoute(
          path: '/triage-result',
          builder: (context, state) => const TriageResultScreen(),
        ),
        GoRoute(
          path: '/hospital-list',
          builder: (context, state) => const HospitalListScreen(),
        ),
        GoRoute(
          path: '/navigation',
          builder: (context, state) => const NavigationScreen(),
        ),
        GoRoute(
          path: '/handover',
          builder: (context, state) => const HandoverScreen(),
        ),
        GoRoute(
          path: '/biometric',
          builder: (context, state) => const BiometricScreen(),
        ),
        GoRoute(
          path: '/explainability',
          builder: (context, state) => const ExplainabilityDashboardScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Jeevan',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
