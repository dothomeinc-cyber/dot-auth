import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/dot_auth_config.dart';
import '../pages/email_screen.dart';
import '../pages/otp_screen.dart';
import '../pages/phone_screen.dart';
import 'router_notifier.dart';

/// Builds a [GoRouter] with the dot_auth routes already wired up.
///
/// Paths come from [dotAuthRoutesProvider], so override [DotAuthConfig] rather
/// than passing paths here. For full control over transitions and shells, skip
/// this and use [RouterNotifier] directly.
class AuthRouter {
  AuthRouter._();

  /// Creates the router.
  ///
  /// - [ref] — the [Ref] from inside a `Provider`.
  /// - [homeBuilder] — your home screen.
  /// - [email] — also register the email route and show the cross-links.
  /// - [termsBuilder] / [privacyBuilder] — optional legal pages. Skip them and
  ///   the footer links will 404, so supply them or point the config at pages
  ///   you register in [additionalRoutes].
  /// - [additionalRoutes] — anything else your app needs. These are protected
  ///   by default: signed-out users get bounced to the phone screen.
  static GoRouter createRouter({
    required Ref ref,
    required Widget Function(BuildContext, GoRouterState) homeBuilder,
    bool email = false,
    Widget Function(BuildContext, GoRouterState)? termsBuilder,
    Widget Function(BuildContext, GoRouterState)? privacyBuilder,
    List<RouteBase> additionalRoutes = const [],
    String? initialLocation,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    final routes = ref.read(dotAuthRoutesProvider);
    final notifier = RouterNotifier(ref);

    // Without this the notifier outlives the provider and leaks its listener.
    ref.onDispose(notifier.dispose);

    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: initialLocation ?? routes.phone,
      refreshListenable: notifier,
      redirect: notifier.redirect,
      routes: [
        GoRoute(
          path: routes.phone,
          name: 'dotAuthPhone',
          pageBuilder: (context, state) => _transition(
            state,
            AuthPhone(emailEnabled: email),
          ),
        ),
        GoRoute(
          path: routes.otp,
          name: 'dotAuthOtp',
          pageBuilder: (context, state) =>
              _transition(state, const OtpScreen()),
        ),
        if (email)
          GoRoute(
            path: routes.email,
            name: 'dotAuthEmail',
            pageBuilder: (context, state) => _transition(
              state,
              const AuthEmail(phoneEnabled: true),
            ),
          ),
        if (termsBuilder != null)
          GoRoute(
            path: routes.terms,
            name: 'dotAuthTerms',
            pageBuilder: (context, state) =>
                _transition(state, termsBuilder(context, state)),
          ),
        if (privacyBuilder != null)
          GoRoute(
            path: routes.privacy,
            name: 'dotAuthPrivacy',
            pageBuilder: (context, state) =>
                _transition(state, privacyBuilder(context, state)),
          ),
        GoRoute(
          path: routes.home,
          name: 'dotAuthHome',
          pageBuilder: (context, state) =>
              _transition(state, homeBuilder(context, state)),
        ),
        ...additionalRoutes,
      ],
    );
  }

  static CustomTransitionPage<void> _transition(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
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
