import 'user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthStateModel {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthStateModel({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthStateModel.initial() {
    return const AuthStateModel(
      status: AuthStatus.initial,
      user: null,
      errorMessage: null,
    );
  }

  factory AuthStateModel.loading() {
    return const AuthStateModel(
      status: AuthStatus.loading,
      user: null,
      errorMessage: null,
    );
  }

  factory AuthStateModel.authenticated(UserModel user) {
    return AuthStateModel(
      status: AuthStatus.authenticated,
      user: user,
      errorMessage: null,
    );
  }

  factory AuthStateModel.unauthenticated() {
    return const AuthStateModel(
      status: AuthStatus.unauthenticated,
      user: null,
      errorMessage: null,
    );
  }

  factory AuthStateModel.error(String message) {
    return AuthStateModel(
      status: AuthStatus.error,
      user: null,
      errorMessage: message,
    );
  }

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

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
}
