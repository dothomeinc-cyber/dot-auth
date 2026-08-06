import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/auth_state_model.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_theme.dart';

/// Switches between [signedIn] and [signedOut] based on the Firebase session.
///
/// Use this when you are not routing with go_router:
///
/// ```dart
/// AuthWrapper(
///   signedIn: const HomeScreen(),
///   signedOut: const AuthPhone(),
///   loading: const SplashScreen(), // optional
/// )
/// ```
class AuthWrapper extends ConsumerWidget {
  /// Shown when a user is signed in.
  final Widget signedIn;

  /// Shown when nobody is signed in.
  final Widget signedOut;

  /// Shown while Firebase resolves the session or an account operation runs.
  final Widget? loading;

  /// Shown when an account operation fails. Defaults to a retry screen.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  const AuthWrapper({
    super.key,
    required this.signedIn,
    required this.signedOut,
    this.loading,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return switch (authState.status) {
      AuthStatus.authenticated => signedIn,
      AuthStatus.initial || AuthStatus.loading => loading ?? const _Loading(),
      AuthStatus.error => errorBuilder?.call(
            context,
            authState.errorMessage ?? 'Something went wrong.',
          ) ??
          _ErrorRetry(
            message: authState.errorMessage ?? 'Something went wrong.',
            onRetry: () => ref.read(authStateProvider.notifier).clearError(),
          ),
      AuthStatus.unauthenticated => signedOut,
    };
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 40.sp, color: AuthColors.black50),
              SizedBox(height: 16.h),
              Text(
                message,
                style: AuthTextStyles.bodyL,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
