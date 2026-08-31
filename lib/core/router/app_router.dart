import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/cms/presentation/cms_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/leads/presentation/leads_screen.dart';
import '../../features/marketing/presentation/marketing_screen.dart';
import '../../features/media/presentation/media_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/pipeline/presentation/pipeline_screen.dart';
import '../../features/properties/presentation/properties_screen.dart';
import '../../features/properties/presentation/property_detail_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/roles/presentation/roles_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/site_visits/presentation/site_visits_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../widgets/layout/main_shell.dart';
import '../config/app_config.dart';
import '../providers/auth_providers.dart';

/// go_router that is permission/role aware.
///
/// - Redirects unauthenticated users to /login.
/// - Bundles authenticated module routes inside MainShell, which only shows
///   destinations the user has `view` permission for.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      switch (authState.status) {
        case AuthStatus.unknown:
          // Still restoring session: keep the user on the splash screen.
          return loc == '/' ? null : '/';

        case AuthStatus.authenticated:
          // An authenticated user shouldn't sit on the splash or login page.
          if (loc == '/' || loc == '/login') return '/dashboard';
          return null;

        case AuthStatus.unauthenticated:
          // Send everyone without a session to the login screen (including
          // the splash, which must not be shown forever once we know there is
          // no cached session).
          if (loc == '/login' || loc == '/forgot-password') return null;
          return '/login';
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      ShellRoute(
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/properties',
            builder: (context, state) => const PropertiesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is PropertyDetailArgs) {
                    return PropertyDetailScreen(
                      initial: extra.property,
                      canEdit: extra.canEdit,
                      canDelete: extra.canDelete,
                    );
                  }
                  return const PropertiesScreen();
                },
              ),
            ],
          ),
          GoRoute(
            path: '/leads',
            builder: (context, state) => const LeadsScreen(),
          ),
          GoRoute(
            path: '/pipeline',
            builder: (context, state) => const PipelineScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/site-visits',
            builder: (context, state) => const SiteVisitsScreen(),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingsScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/media',
            builder: (context, state) => const MediaScreen(),
          ),
          GoRoute(
            path: '/marketing',
            builder: (context, state) => const MarketingScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/cms',
            builder: (context, state) => const CmsScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/roles',
            builder: (context, state) => const RolesScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
        builder: (context, state, child) => MainShell(
          currentLocation: state.matchedLocation,
          child: child,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Text(
          'No route for ${state.uri}. ${AppConfig.appName}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
});

/// Listens for auth state changes and asks the router to refresh redirects.
class _AuthRefresh extends ChangeNotifier {
  final Ref _ref;

  _AuthRefresh(this._ref) {
    _ref.listen(authControllerProvider, (prev, next) => notifyListeners(),
        fireImmediately: false);
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              child: const Text('Q', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
