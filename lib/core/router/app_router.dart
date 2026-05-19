import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/patients/presentation/screens/patient_registration_screen.dart';
import '../../features/patients/presentation/screens/patient_search_screen.dart';
import '../../features/patients/presentation/screens/patient_dashboard_screen.dart';
import '../../features/patients/presentation/screens/patient_list_screen.dart';
import '../../features/patients/presentation/screens/history_screen.dart';
import '../../features/vitals/presentation/screens/vitals_dashboard_screen.dart';
import '../../features/medications/presentation/screens/medication_dashboard.dart';
import '../../features/reports/presentation/screens/reports_dashboard.dart';
import '../../features/reports/presentation/screens/report_preview_screen.dart';
import '../../features/reports/presentation/screens/global_reports_screen.dart';
import '../../features/patients/presentation/screens/archived_patients_screen.dart';
import '../../features/notes/presentation/screens/notes_screen.dart';
import '../../features/admin/presentation/screens/settings_screen.dart';
import '../../features/patients/presentation/screens/edit_patient_screen.dart';
import '../widgets/main_shell.dart';

import '../../core/auth/auth_provider.dart';
import '../../features/admin/presentation/screens/staff_management_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authProvider.select((state) => state.user));

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = user != null;
      final isGoingToSplash = state.matchedLocation == '/';
      final isGoingToLogin = state.matchedLocation == '/login';

      if (isGoingToSplash) return null;

      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      if (isLoggedIn && isGoingToLogin) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/register_patient', builder: (c, s) => const PatientRegistrationScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/search_patient', builder: (c, s) => const PatientSearchScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/reports_list', builder: (c, s) => const GlobalReportsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/archived_patients', builder: (c, s) => const ArchivedPatientsScreen()),
            ],
          ),
        ],
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin',
        builder: (c, s) => const StaffManagementScreen(),
      ),

      // Patient Dashboard and sub-screens (Nested but can hide bottom nav if navigated via push)
      // Or we can put them inside the Search branch if we want them to stay there.
      // But usually, a dashboard is a dedicated context.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/patient_dashboard/:patientId',
        builder: (c, s) => PatientDashboardScreen(patientId: s.pathParameters['patientId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/edit_patient/:patientId',
        builder: (c, s) => EditPatientScreen(patientId: s.pathParameters['patientId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/vitals/:patientId',
        builder: (c, s) => VitalsScreen(patientId: s.pathParameters['patientId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/medications/:patientId',
        builder: (c, s) => MedicationDashboard(patientId: s.pathParameters['patientId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notes/:patientId',
        builder: (c, s) => NotesScreen(patientId: s.pathParameters['patientId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reports/:patientId',
        builder: (c, s) => ReportsDashboard(patientId: s.pathParameters['patientId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/report_preview/:patientId',
        builder: (c, s) => ReportPreviewScreen(patientId: s.pathParameters['patientId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/history/:patientId',
        builder: (c, s) => HistoryScreen(patientId: s.pathParameters['patientId']!),
      ),
    ],
  );
});