/// The active screen within [AuthEmail].
enum EmailAuthMode {
  /// Sign in with email and password.
  signIn,

  /// Create a new account with email and password.
  signUp,

  /// Send a password reset link to the user's email.
  forgotPassword,
}

/// Immutable state for the email authentication flow.
///
/// Managed by [EmailAuthNotifier] and exposed via [emailAuthProvider].
class EmailAuthModel {
  /// Last email address entered by the user.
  final String? email;

  /// `true` while a Firebase operation is in progress.
  final bool isLoading;

  /// Human-readable Firebase error message, or `null` if no error.
  final String? error;

  /// `true` after a password reset email has been sent successfully.
  final bool isPasswordResetSent;

  /// Current active mode within the email screen.
  final EmailAuthMode mode;

  const EmailAuthModel({
    this.email,
    this.isLoading = false,
    this.error,
    this.isPasswordResetSent = false,
    this.mode = EmailAuthMode.signIn,
  });

  /// Initial empty state — mode defaults to [EmailAuthMode.signIn].
  factory EmailAuthModel.initial() => const EmailAuthModel();

  /// Returns a copy with the given fields replaced.
  EmailAuthModel copyWith({
    String? email,
    bool? isLoading,
    String? error,
    bool? isPasswordResetSent,
    EmailAuthMode? mode,
  }) {
    return EmailAuthModel(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isPasswordResetSent: isPasswordResetSent ?? this.isPasswordResetSent,
      mode: mode ?? this.mode,
    );
  }

  /// Returns a copy with [error] set to `null`.
  EmailAuthModel clearError() => copyWith(error: null);
}
