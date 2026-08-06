import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_state_model.dart';
import '../models/user_model.dart';
import '../utils/auth_error_mapper.dart';
import 'email_auth_provider.dart';
import 'firebase_providers.dart';
import 'phone_auth_provider.dart';

/// Tracks the Firebase session and performs account-level operations.
///
/// The session is seeded synchronously from `FirebaseAuth.currentUser` on the
/// first build, so a returning user never sees a blank frame.
class AuthStateNotifier extends Notifier<AuthStateModel> {
  bool _disposed = false;
  bool _ready = false;

  // Cached at build time — callbacks may outlive the provider.
  late FirebaseAuth _auth;

  @override
  AuthStateModel build() {
    final auth = ref.read(firebaseAuthProvider);
    _auth = auth;

    final subscription = auth.authStateChanges().listen(
          _onAuthStateChanged,
          onError: (Object e) => _emit(
            AuthStateModel.error('Lost connection to the account service.'),
          ),
        );

    ref.onDispose(() {
      _disposed = true;
      subscription.cancel();
    });

    final current = auth.currentUser;
    _ready = true;
    if (current == null) return AuthStateModel.unauthenticated();
    return AuthStateModel.authenticated(UserModel.fromFirebaseUser(current));
  }

  void _emit(AuthStateModel next) {
    if (_disposed) return;
    state = next;
  }

  void _onAuthStateChanged(User? firebaseUser) {
    final next = firebaseUser == null
        ? AuthStateModel.unauthenticated()
        : AuthStateModel.authenticated(UserModel.fromFirebaseUser(firebaseUser));

    // Guard against an emission that lands before build() has returned.
    if (!_ready) {
      scheduleMicrotask(() => _emit(next));
      return;
    }
    _emit(next);
  }

  /// Signs the current user out and clears both auth flows.
  Future<void> signOut() async {
    _emit(AuthStateModel.loading());
    try {
      await _auth.signOut();
      ref.read(phoneAuthProvider.notifier).reset();
      ref.read(emailAuthProvider.notifier).reset();
    } on FirebaseAuthException catch (e) {
      _emit(AuthStateModel.error(mapAuthError(e.code)));
    } catch (_) {
      _emit(AuthStateModel.error('Could not sign out. Try again.'));
    }
  }

  /// Refetches the profile from Firebase.
  ///
  /// Call this after the user clicks a verification link — `emailVerified` is
  /// cached on the client and will otherwise stay stale.
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null) return;
      _emit(AuthStateModel.authenticated(
        UserModel.fromFirebaseUser(refreshed),
      ));
    } catch (_) {
      // A failed refresh leaves the cached profile in place — not worth
      // interrupting the user over.
    }
  }

  /// Sends a verification email to the signed-in user.
  Future<bool> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (user.emailVerified) return true;
    try {
      await user.sendEmailVerification();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Re-authenticates with [password] for the signed-in email account.
  ///
  /// Firebase requires this before deleting an account or changing a password
  /// if the last sign-in was more than a few minutes ago.
  Future<bool> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return false;
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _emit(state.copyWith(errorMessage: mapAuthError(e.code)));
      return false;
    }
  }

  /// Changes the signed-in user's password.
  ///
  /// Call [reauthenticateWithPassword] first if this returns a
  /// `requires-recent-login` failure.
  Future<bool> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _emit(state.copyWith(errorMessage: mapAuthError(e.code)));
      return false;
    }
  }

  /// Connects an email/password credential to the signed-in account.
  ///
  /// Lets someone who signed up by phone add an email login without ending up
  /// with two separate accounts.
  Future<bool> linkEmailPassword(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.linkWithCredential(
        EmailAuthProvider.credential(email: email.trim(), password: password),
      );
      await reloadUser();
      return true;
    } on FirebaseAuthException catch (e) {
      _emit(state.copyWith(errorMessage: mapAuthError(e.code)));
      return false;
    }
  }

  /// Connects a phone credential to the signed-in account.
  ///
  /// Pass the `verificationId` from `phoneAuthProvider` and the code the user
  /// typed.
  Future<bool> linkPhoneNumber(String verificationId, String smsCode) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.linkWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        ),
      );
      await reloadUser();
      return true;
    } on FirebaseAuthException catch (e) {
      _emit(state.copyWith(errorMessage: mapAuthError(e.code)));
      return false;
    }
  }

  /// Permanently deletes the signed-in account.
  ///
  /// The App Store and Play Store both require an in-app path to this. Returns
  /// `false` and sets [AuthStateModel.errorMessage] when Firebase needs a fresh
  /// sign-in first — re-authenticate, then call this again.
  Future<bool> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _emit(AuthStateModel.loading());
    try {
      await user.delete();
      ref.read(phoneAuthProvider.notifier).reset();
      ref.read(emailAuthProvider.notifier).reset();
      return true;
    } on FirebaseAuthException catch (e) {
      _emit(AuthStateModel.authenticated(UserModel.fromFirebaseUser(user))
          .copyWith(errorMessage: mapAuthError(e.code)));
      return false;
    } catch (_) {
      _emit(AuthStateModel.authenticated(UserModel.fromFirebaseUser(user))
          .copyWith(errorMessage: 'Could not delete the account. Try again.'));
      return false;
    }
  }

  /// Clears the last account error without changing the session.
  void clearError() {
    if (state.errorMessage == null) return;
    _emit(state.copyWith(errorMessage: null));
  }
}

/// The Firebase session — the source of truth for whether anyone is signed in.
final authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthStateModel>(
  AuthStateNotifier.new,
);

/// The signed-in [UserModel], or `null`.
final currentUserProvider = Provider<UserModel?>(
  (ref) => ref.watch(authStateProvider).user,
);

/// `true` when a user is signed in.
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).isAuthenticated,
);

/// `true` when the signed-in user has a verified email address.
///
/// Also `true` for phone-only accounts, which have no email to verify — gate
/// on `currentUserProvider?.email` first if you need to tell them apart.
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  if (user.email == null) return true;
  return user.isEmailVerified;
});
