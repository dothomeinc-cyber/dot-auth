import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/dot_auth_config.dart';
import '../models/email_auth_model.dart';
import '../utils/auth_error_mapper.dart';
import 'firebase_providers.dart';

/// Owns the email/password flow: sign in, sign up, and password reset.
///
/// Each method returns `true` on success so callers can react without
/// inspecting [state] — inspecting state to detect success is fragile, because
/// a stale error from an earlier attempt would poison the check.
class EmailAuthNotifier extends Notifier<EmailAuthModel> {
  bool _disposed = false;

  late FirebaseAuth _auth;
  late DotAuthConfig _config;

  @override
  EmailAuthModel build() {
    _auth = ref.read(firebaseAuthProvider);
    _config = ref.read(dotAuthConfigProvider);
    ref.onDispose(() => _disposed = true);
    return EmailAuthModel.initial();
  }

  void _emit(EmailAuthModel next) {
    if (_disposed) return;
    state = next;
  }

  /// Switches mode and clears anything left over from the previous one.
  void setMode(EmailAuthMode mode) => _emit(state.copyWith(
        mode: mode,
        error: null,
        isPasswordResetSent: false,
        isVerificationEmailSent: false,
        isLoading: false,
      ));

  /// Clears the current error.
  void clearError() {
    if (state.error == null) return;
    _emit(state.copyWith(error: null));
  }

  /// Resets to the initial state.
  void reset() => _emit(EmailAuthModel.initial());

  /// Signs in with [email] and [password].
  ///
  /// Returns `true` on success. The Firebase auth stream then drives
  /// `authStateProvider`, so callers should not navigate manually.
  Future<bool> signIn(String email, String password) async {
    final trimmed = email.trim();
    _emit(state.copyWith(isLoading: true, error: null, email: trimmed));
    try {
      await _auth.signInWithEmailAndPassword(
        email: trimmed,
        password: password,
      );
      _emit(state.copyWith(isLoading: false, error: null));
      return true;
    } on FirebaseAuthException catch (e) {
      _emit(state.copyWith(isLoading: false, error: mapAuthError(e.code)));
      return false;
    } catch (_) {
      _emit(state.copyWith(
        isLoading: false,
        error: 'Could not sign in. Try again.',
      ));
      return false;
    }
  }

  /// Creates an account with [email] and [password].
  ///
  /// When [DotAuthConfig.sendVerificationEmailOnSignUp] is set, a verification
  /// email goes out immediately and [EmailAuthModel.isVerificationEmailSent]
  /// becomes `true`. A failure to send the verification email does not fail the
  /// sign-up — the account exists either way.
  Future<bool> signUp(String email, String password) async {
    final trimmed = email.trim();
    _emit(state.copyWith(isLoading: true, error: null, email: trimmed));
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmed,
        password: password,
      );

      var verificationSent = false;
      if (_config.sendVerificationEmailOnSignUp) {
        try {
          await credential.user?.sendEmailVerification();
          verificationSent = true;
        } catch (_) {
          verificationSent = false;
        }
      }

      _emit(state.copyWith(
        isLoading: false,
        error: null,
        isVerificationEmailSent: verificationSent,
      ));
      return true;
    } on FirebaseAuthException catch (e) {
      _emit(state.copyWith(isLoading: false, error: mapAuthError(e.code)));
      return false;
    } catch (_) {
      _emit(state.copyWith(
        isLoading: false,
        error: 'Could not create the account. Try again.',
      ));
      return false;
    }
  }

  /// Sends a password reset link to [email].
  ///
  /// Always reports success, even when no account exists, so the form cannot
  /// be used to discover which emails are registered.
  Future<bool> sendPasswordReset(String email) async {
    final trimmed = email.trim();
    _emit(state.copyWith(isLoading: true, error: null, email: trimmed));
    try {
      await _auth.sendPasswordResetEmail(email: trimmed);
      _emit(state.copyWith(isLoading: false, isPasswordResetSent: true));
      return true;
    } on FirebaseAuthException catch (e) {
      // Don't leak account existence.
      if (e.code == 'user-not-found') {
        _emit(state.copyWith(isLoading: false, isPasswordResetSent: true));
        return true;
      }
      _emit(state.copyWith(isLoading: false, error: mapAuthError(e.code)));
      return false;
    } catch (_) {
      _emit(state.copyWith(
        isLoading: false,
        error: 'Could not send the reset link. Try again.',
      ));
      return false;
    }
  }
}

/// Email/password flow state and actions.
final emailAuthProvider =
    NotifierProvider<EmailAuthNotifier, EmailAuthModel>(
  EmailAuthNotifier.new,
);
