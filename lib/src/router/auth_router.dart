import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';

import '../pages/phone_screen.dart';
import '../pages/otp_screen.dart';
import '../pages/email_screen.dart';
import 'router_notifier.dart';

/// Optional convenience factory that wires up a fully configured [GoRouter].
///
/// For manual GoRouter setup — which gives you full control over routes,
/// redirect logic, and animations — use [RouterNotifier] directly.
/// See `example/lib/main.dart` for the recommended manual approach.
///
/// Example using [AuthRouter]:
/// ```dart
/// final routerProvider = Provider<GoRouter>((ref) {
///   return AuthRouter.createRouter(
///     ref: ref,
///     homeRoute: '/home',
///     homeBuilder: (_, __) => const HomeScreen(),
///     email: true,
///   );
/// });
/// ```
class AuthRouter {
  /// Creates a [GoRouter] with all dot_auth routes pre-configured.
  ///
  /// - [ref] — Riverpod [Ref] from inside a `Provider`.
  /// - [homeRoute] — your home path, e.g. `'/home'`.
  /// - [homeBuilder] — builder for your home screen.
  /// - [email] — registers `/email` and shows email toggle on phone screen.
  /// - [additionalRoutes] — any extra [GoRoute]s your app needs.
  /// - [initialLocation] — defaults to `'/phone'`.
  static GoRouter createRouter({
    required Ref ref,
    required String homeRoute,
    required Widget Function(BuildContext, GoRouterState) homeBuilder,
    bool email = false,
    List<GoRoute> additionalRoutes = const [],
    String initialLocation = '/phone',
  }) {
    final routerNotifier = RouterNotifier(ref);

    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: routerNotifier,
      redirect: routerNotifier.redirect,
      routes: [
        GoRoute(
          path: '/phone',
          name: 'phone',
          pageBuilder: (context, state) => _slide(
            state,
            AuthPhone(emailEnabled: email),
          ),
        ),
        GoRoute(
          path: '/otp',
          name: 'otp',
          pageBuilder: (context, state) => _slide(state, const OtpScreen()),
        ),
        if (email)
          GoRoute(
            path: '/email',
            name: 'email',
            pageBuilder: (context, state) => _slide(
              state,
              const AuthEmail(phoneEnabled: true),
            ),
          ),
        GoRoute(
          path: homeRoute,
          name: 'home',
          pageBuilder: (context, state) =>
              _slide(state, homeBuilder(context, state)),
        ),
        ...additionalRoutes,
      ],
    );
  }

  /// Shared axis horizontal slide transition — used for all auth routes.
  static CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    );
  }
}
