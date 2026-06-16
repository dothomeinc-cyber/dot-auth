import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

// ─── Phone Auth ────────────────────────────────────────────────────────────

/// Manages phone OTP verification state.
///
/// All Firebase calls for phone auth live in [phone_screen.dart] and
/// [otp_screen.dart] — this notifier stores and exposes the resulting state.
class PhoneAuthNotifier extends Notifier<PhoneAuthModel> {
  @override
  PhoneAuthModel build() => PhoneAuthModel.initial();

  /// Stores the international phone number after it is entered.
  void setPhoneNumber(String phoneNumber) =>
      state = state.copyWith(phoneNumber: phoneNumber);

  /// Stores the Firebase [verificationId] and optional [resendToken] received
  /// in the [codeSent] callback. Sets [isCodeSent] to `true`.
  void setVerificationData(String verificationId, int? resendToken) {
    state = state.copyWith(
      verificationId: verificationId,
      isCodeSent: true,
      isLoading: false,
      resendToken: resendToken,
    );
  }

  /// Sets the loading flag.
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);

  /// Sets an error message and clears loading.
  void setError(String error) =>
      state = state.copyWith(error: error, isLoading: false);

  /// Clears any current error.
  void clearError() => state = state.clearError();

  /// Resets to initial state — called after successful sign-in.
  void reset() => state = PhoneAuthModel.initial();

  /// Stores the OTP code as the user types.
  void setOtp(String otp) => state = state.setOtp(otp);
}

/// Provides phone OTP verification state across the auth flow.
final phoneAuthProvider =
    NotifierProvider<PhoneAuthNotifier, PhoneAuthModel>(
  PhoneAuthNotifier.new,
);

// ─── Email Auth ────────────────────────────────────────────────────────────

/// Manages email/password authentication state and Firebase operations.
///
/// All Firebase calls (sign in, sign up, password reset) are encapsulated
/// here — screens only call notifier methods and read the resulting state.
class EmailAuthNotifier extends Notifier<EmailAuthModel> {
  @override
  EmailAuthModel build() => EmailAuthModel.initial();

  /// Stores the email address entered by the user.
  void setEmail(String email) => state = state.copyWith(email: email);

  /// Switches between [EmailAuthMode] values and resets error + reset flag.
  void setMode(EmailAuthMode mode) => state = state.copyWith(
        mode: mode,
        error: null,
        isPasswordResetSent: false,
      );

  /// Sets the loading flag.
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);

  /// Sets an error message and clears loading.
  void setError(String error) =>
      state = state.copyWith(error: error, isLoading: false);

  /// Clears any current error.
  void clearError() => state = state.clearError();

  /// Resets to initial state.
  void reset() => state = EmailAuthModel.initial();

  /// Signs in with [email] and [password].
  ///
  /// On success, [authStateProvider] updates automatically via the Firebase
  /// auth stream. On failure, [EmailAuthModel.error] is set.
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, email: email);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e.code));
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred.');
    }
  }

  /// Creates a new account with [email] and [password].
  ///
  /// On success, [authStateProvider] updates automatically.
  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, email: email);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e.code));
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred.');
    }
  }

  /// Sends a password reset email to [email].
  ///
  /// On success, [EmailAuthModel.isPasswordResetSent] becomes `true`.
  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null, email: email);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      state = state.copyWith(isPasswordResetSent: true, isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e.code));
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred.');
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Provides email authentication state and Firebase operations.
final emailAuthProvider =
    NotifierProvider<EmailAuthNotifier, EmailAuthModel>(
  EmailAuthNotifier.new,
);

// ─── Main Auth State ───────────────────────────────────────────────────────

/// Listens to Firebase auth state changes and exposes the current session.
///
/// Seeds from [FirebaseAuth.instance.currentUser] immediately on first build
/// so there is no blank loading flash on app restart.
class AuthStateNotifier extends Notifier<AuthStateModel> {
  @override
  AuthStateModel build() {
    final sub = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthStateChanged,
      onError: (e) => state = AuthStateModel.error('Auth error: $e'),
    );
    ref.onDispose(sub.cancel);

    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      return AuthStateModel.authenticated(UserModel.fromFirebaseUser(current));
    }
    return AuthStateModel.unauthenticated();
  }

  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser != null) {
      state = AuthStateModel.authenticated(
        UserModel.fromFirebaseUser(firebaseUser),
      );
    } else {
      state = AuthStateModel.unauthenticated();
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = AuthStateModel.loading();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      state = AuthStateModel.error('Failed to sign out: $e');
    }
  }
}

/// Provides the main Firebase authentication session state.
///
/// Automatically updates whenever the Firebase auth state changes.
final authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthStateModel>(
  AuthStateNotifier.new,
);

/// Convenience provider — the currently signed-in [UserModel], or `null`.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).user;
});

/// Convenience provider — `true` when a user is signed in.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});
