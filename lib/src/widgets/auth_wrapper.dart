import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state_model.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget authenticatedChild;
  final Widget unauthenticatedChild;
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

    switch (authState.status) {
      case AuthStatus.authenticated:
        return authenticatedChild;
      case AuthStatus.unauthenticated:
        return unauthenticatedChild;
      case AuthStatus.loading:
        return loadingWidget ??
            const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
      default:
        return unauthenticatedChild;
    }
  }
}
