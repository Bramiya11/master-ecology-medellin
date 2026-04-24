import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../views/shared/login_screen.dart';
import '../views/shared/map_screen.dart';
import '../views/shared/report_form_screen.dart';
import '../views/shared/profile_screen.dart';
import '../views/citizen/citizen_shell.dart';
import '../views/recycler/recycler_shell.dart';
import '../views/recycler/recycler_routes_screen.dart';
import '../views/admin/admin_shell.dart';
import '../views/admin/admin_dashboard_screen.dart';
import '../views/admin/admin_reports_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) {
        return switch (authState.user!.role) {
          UserRole.citizen => '/citizen/map',
          UserRole.recycler => '/recycler/routes',
          UserRole.admin => '/admin/dashboard',
          _ => '/citizen/map',
        };
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Citizen shell ──────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => CitizenShell(child: child),
        routes: [
          GoRoute(
            path: '/citizen/map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/citizen/report',
            builder: (context, state) => const ReportFormScreen(),
          ),
          GoRoute(
            path: '/citizen/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Recycler shell ─────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => RecyclerShell(child: child),
        routes: [
          GoRoute(
            path: '/recycler/routes',
            builder: (context, state) => const RecyclerRoutesScreen(),
          ),
          GoRoute(
            path: '/recycler/map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/recycler/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Admin shell ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '/admin/map',
            builder: (context, state) => const MapScreen(),
          ),
        ],
      ),
    ],
  );
});
