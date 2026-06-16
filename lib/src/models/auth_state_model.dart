import 'user_model.dart';

/// Possible states of the Firebase authentication session.
enum AuthStatus {
  /// Initial state before Firebase has responded.
  initial,

  /// A sign-in or sign-out operation is in progress.
  loading,

  /// User is signed in. [AuthStateModel.user] is non-null.
  authenticated,

  /// No user is signed in.
  unauthenticated,

  /// An error occurred. [AuthStateModel.errorMessage] contains the reason.
  error,
}

/// Immutable snapshot of the current authentication session.
///
/// Managed by [AuthStateNotifier] and exposed via [authStateProvider].
class AuthStateModel {
  /// Current authentication status.
  final AuthStatus status;

  /// Signed-in user — non-null only when [status] is [AuthStatus.authenticated].
  final UserModel? user;

  /// Error message — non-null only when [status] is [AuthStatus.error].
  final String? errorMessage;

  const AuthStateModel({
    required this.status,
    this.user,
    this.errorMessage,
  });

  /// Waiting for Firebase to respond.
  factory AuthStateModel.initial() => const AuthStateModel(
        status: AuthStatus.initial,
      );

  /// An operation is in progress.
  factory AuthStateModel.loading() => const AuthStateModel(
        status: AuthStatus.loading,
      );

  /// User is signed in.
  factory AuthStateModel.authenticated(UserModel user) => AuthStateModel(
        status: AuthStatus.authenticated,
        user: user,
      );

  /// No user signed in.
  factory AuthStateModel.unauthenticated() => const AuthStateModel(
        status: AuthStatus.unauthenticated,
      );

  /// An error occurred.
  factory AuthStateModel.error(String message) => AuthStateModel(
        status: AuthStatus.error,
        errorMessage: message,
      );

  /// Returns a copy with the given fields replaced.
  AuthStateModel copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthStateModel(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// `true` when the user is signed in.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// `true` when an operation is in progress.
  bool get isLoading => status == AuthStatus.loading;

  /// `true` when no user is signed in.
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
}
