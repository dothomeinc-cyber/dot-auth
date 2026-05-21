import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import '../providers/auth_provider.dart';
import '../pages/phone_screen.dart';
import '../pages/otp_screen.dart';
import 'router_notifier.dart';

class AuthRouter {
  static GoRouter createRouter({
    required WidgetRef ref,
    required String homeRoute,
    required Widget Function(
            BuildContext context, GoRouterState state)
        homeBuilder,
    List<GoRoute> additionalRoutes = const [],
    String initialLocation = '/phone',
  }) {
    final routerNotifier =
        RouterNotifier(ref as Ref<Object?>);

    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: routerNotifier,
      redirect: routerNotifier.redirect,
      routes: [
        GoRoute(
          path: '/phone',
          name: 'phone',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const AuthPhone(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType:
                      SharedAxisTransitionType.horizontal,
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/otp',
          name: 'otp',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const OtpScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType:
                      SharedAxisTransitionType.horizontal,
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: homeRoute,
          name: 'home',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: homeBuilder(context, state),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType:
                      SharedAxisTransitionType.horizontal,
                  child: child,
                );
              },
            );
          },
        ),
        ...additionalRoutes,
      ],
    );
  }
}
