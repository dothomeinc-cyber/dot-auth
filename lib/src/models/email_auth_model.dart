import 'package:flutter/foundation.dart';

import '_copy_with.dart';

/// The active screen within `AuthEmail`.
enum EmailAuthMode {
  /// Sign in with email and password.
  signIn,

  /// Create a new account.
  signUp,

  /// Send a password reset link.
  forgotPassword,
}

/// Immutable state for the email flow.
@immutable
class EmailAuthModel {
  /// Current mode.
  final EmailAuthMode mode;

  /// Last email address the user submitted.
  final String? email;

  /// `true` while a Firebase call is in flight.
  final bool isLoading;

  /// User-facing failure message, or `null`.
  final String? error;

  /// `true` after a password reset link was sent.
  final bool isPasswordResetSent;

  /// `true` after a verification email was sent following sign-up.
  final bool isVerificationEmailSent;

  const EmailAuthModel({
    this.mode = EmailAuthMode.signIn,
    this.email,
    this.isLoading = false,
    this.error,
    this.isPasswordResetSent = false,
    this.isVerificationEmailSent = false,
  });

  /// Initial empty state — mode defaults to [EmailAuthMode.signIn].
  factory EmailAuthModel.initial() => const EmailAuthModel();

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields accept an explicit `null` to clear them.
  EmailAuthModel copyWith({
    EmailAuthMode? mode,
    Object? email = kUnset,
    bool? isLoading,
    Object? error = kUnset,
    bool? isPasswordResetSent,
    bool? isVerificationEmailSent,
  }) {
    return EmailAuthModel(
      mode: mode ?? this.mode,
      email: pick<String>(email, this.email),
      isLoading: isLoading ?? this.isLoading,
      error: pick<String>(error, this.error),
      isPasswordResetSent: isPasswordResetSent ?? this.isPasswordResetSent,
      isVerificationEmailSent:
          isVerificationEmailSent ?? this.isVerificationEmailSent,
    );
  }

  /// Returns a copy with [error] genuinely cleared.
  EmailAuthModel clearError() => copyWith(error: null);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailAuthModel &&
        other.mode == mode &&
        other.email == email &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isPasswordResetSent == isPasswordResetSent &&
        other.isVerificationEmailSent == isVerificationEmailSent;
  }

  @override
  int get hashCode => Object.hash(
        mode,
        email,
        isLoading,
        error,
        isPasswordResetSent,
        isVerificationEmailSent,
      );

  @override
  String toString() => 'EmailAuthModel(mode: $mode, email: $email, '
      'loading: $isLoading, error: $error)';
}
