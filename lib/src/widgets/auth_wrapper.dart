import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state_model.dart';

/// Switches between [authenticatedChild] and [unauthenticatedChild] based on
/// the current [authStateProvider] status.
///
/// Useful when not using go_router — place at the root of your widget tree:
///
/// ```dart
/// AuthWrapper(
///   authenticatedChild: const HomeScreen(),
///   unauthenticatedChild: const AuthPhone(),
///   loadingWidget: const SplashScreen(), // optional
/// )
/// ```
class AuthWrapper extends ConsumerWidget {
  /// Widget shown when the user is signed in.
  final Widget authenticatedChild;

  /// Widget shown when no user is signed in.
  final Widget unauthenticatedChild;

  /// Optional widget shown while Firebase resolves the auth state.
  /// Defaults to a centered [CircularProgressIndicator].
  final Widget? loadingWidget;

  const AuthWrapper({
    super.key,
    required this.authenticatedChild,
    required this.unauthenticatedChild,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return switch (authState.status) {
      AuthStatus.authenticated => authenticatedChild,
      AuthStatus.loading => loadingWidget ??
          const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
      _ => unauthenticatedChild,
    };
  }
}
