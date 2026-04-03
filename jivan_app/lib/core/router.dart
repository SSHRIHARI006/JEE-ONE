import 'package:go_router/go_router.dart';
// Note: Imports to screens will be resolved as they are created.
// To avoid compilation errors right now, these screens will be created next.
import '../screens/home_screen.dart';
import '../screens/emergency_reporting.dart';
import '../screens/case_intake.dart';
import '../screens/triage_loading_screen.dart';
import '../screens/triage_result_screen.dart';
import '../screens/hospital_list_screen.dart';
import '../screens/navigation_screen.dart';
import '../screens/handover_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/report',
      builder: (context, state) => const EmergencyReportingScreen(),
    ),
    GoRoute(
      path: '/intake',
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
      path: '/hospitals',
      builder: (context, state) => const HospitalListScreen(),
    ),
    GoRoute(
      path: '/navigation',
      builder: (context, state) => const NavigationScreen(), // Needs HospitalModel passed later
    ),
    GoRoute(
      path: '/handover',
      builder: (context, state) => const HandoverScreen(),
    ),
  ],
);
