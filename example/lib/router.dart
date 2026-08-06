import 'package:dot_auth/dot_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/dashboard_screen.dart';
import 'screens/legal_page.dart';
import 'screens/orders_screen.dart';

/// The convenience path: [AuthRouter] wires up the auth routes, the redirect,
/// and the transitions from [DotAuthConfig].
final routerProvider = Provider<GoRouter>((ref) {
  return AuthRouter.createRouter(
    ref: ref,
    email: true,
    homeBuilder: (_, __) => const DashboardScreen(),
    termsBuilder: (_, __) => const LegalPage(title: 'Terms & Conditions'),
    privacyBuilder: (_, __) => const LegalPage(title: 'Privacy Policy'),
    additionalRoutes: [
      // Protected automatically — the redirect denies by default, so a
      // signed-out user hitting /orders lands on the phone screen.
      GoRoute(
        path: '/orders',
        builder: (_, __) => const OrdersScreen(),
      ),
    ],
  );
});

/// The manual path, for when you need shells, nested navigators, or your own
/// transitions. Swap [routerProvider] for this to try it.
///
/// The `ref.onDispose` line is not optional: without it the notifier keeps its
/// listener on `authStateProvider` alive for the life of the process.
final manualRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  final routes = ref.read(dotAuthRoutesProvider);

  return GoRouter(
    initialLocation: routes.phone,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: routes.phone,
        builder: (_, __) => const AuthPhone(emailEnabled: true),
      ),
      GoRoute(path: routes.otp, builder: (_, __) => const OtpScreen()),
      GoRoute(
        path: routes.email,
        builder: (_, __) => const AuthEmail(phoneEnabled: true),
      ),
      GoRoute(path: routes.home, builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: routes.terms,
        builder: (_, __) => const LegalPage(title: 'Terms & Conditions'),
      ),
      GoRoute(
        path: routes.privacy,
        builder: (_, __) => const LegalPage(title: 'Privacy Policy'),
      ),
    ],
  );
});
