import 'package:flutter/foundation.dart';

import '_copy_with.dart';
import 'user_model.dart';

/// State of the Firebase authentication session.
enum AuthStatus {
  /// Firebase has not reported yet. Only seen if the session is seeded
  /// asynchronously — the default notifier resolves this on the first frame.
  initial,

  /// A sign-out, delete, or re-authentication is in flight.
  loading,

  /// A user is signed in. [AuthStateModel.user] is non-null.
  authenticated,

  /// No user is signed in.
  unauthenticated,

  /// The last account operation failed. [AuthStateModel.errorMessage] says why.
  error,
}

/// Immutable snapshot of the current authentication session.
@immutable
class AuthStateModel {
  /// Current status.
  final AuthStatus status;

  /// Signed-in user — non-null only when [status] is
  /// [AuthStatus.authenticated].
  final UserModel? user;

  /// Failure message — non-null only when [status] is [AuthStatus.error].
  final String? errorMessage;

  const AuthStateModel({
    required this.status,
    this.user,
    this.errorMessage,
  });

  /// Waiting on Firebase.
  factory AuthStateModel.initial() =>
      const AuthStateModel(status: AuthStatus.initial);

  /// An account operation is in flight.
  factory AuthStateModel.loading() =>
      const AuthStateModel(status: AuthStatus.loading);

  /// A user is signed in.
  factory AuthStateModel.authenticated(UserModel user) =>
      AuthStateModel(status: AuthStatus.authenticated, user: user);

  /// No user is signed in.
  factory AuthStateModel.unauthenticated() =>
      const AuthStateModel(status: AuthStatus.unauthenticated);

  /// An account operation failed.
  factory AuthStateModel.error(String message) =>
      AuthStateModel(status: AuthStatus.error, errorMessage: message);

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields accept an explicit `null` to clear them.
  AuthStateModel copyWith({
    AuthStatus? status,
    Object? user = kUnset,
    Object? errorMessage = kUnset,
  }) {
    return AuthStateModel(
      status: status ?? this.status,
      user: pick<UserModel>(user, this.user),
      errorMessage: pick<String>(errorMessage, this.errorMessage),
    );
  }

  /// `true` when a user is signed in.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// `true` while an account operation is in flight, or before Firebase has
  /// reported. Use this to decide whether to show a splash.
  bool get isResolving =>
      status == AuthStatus.loading || status == AuthStatus.initial;

  /// `true` when no user is signed in.
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  /// `true` while an account operation is in flight.
  ///
  /// Narrower than [isResolving], which also covers [AuthStatus.initial].
  /// Reach for [isResolving] when deciding whether to show a splash, and this
  /// when reacting to a sign-out or delete specifically.
  bool get isLoading => status == AuthStatus.loading;

  /// `true` when the last account operation failed.
  bool get hasError => status == AuthStatus.error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthStateModel &&
        other.status == status &&
        other.user == user &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(status, user, errorMessage);

  @override
  String toString() =>
      'AuthStateModel(status: $status, uid: ${user?.uid}, '
      'error: $errorMessage)';
}
