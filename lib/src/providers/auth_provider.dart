import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

// Phone Auth Notifier - Legacy StateNotifier
class PhoneAuthNotifier extends StateNotifier<PhoneAuthModel> {
  PhoneAuthNotifier() : super(PhoneAuthModel.initial());

  void setPhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber);
  }

  void setVerificationId(String verificationId) {
    state = state.copyWith(
      verificationId: verificationId,
      isCodeSent: true,
      isLoading: false,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clearError() {
    state = state.clearError();
  }

  void reset() {
    state = PhoneAuthModel.initial();
  }

  void setOtp(String otp) {
    state = state.setOtp(otp);
  }
}

final phoneAuthProvider =
    StateNotifierProvider<PhoneAuthNotifier, PhoneAuthModel>(
  (ref) => PhoneAuthNotifier(),
);

// Main Auth State Notifier - Legacy StateNotifier
class AuthStateNotifier extends StateNotifier<AuthStateModel> {
  AuthStateNotifier() : super(AuthStateModel.initial()) {
    // Listen to Firebase auth changes
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
    // Check current user immediately
    _onAuthStateChanged(FirebaseAuth.instance.currentUser);
  }

  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser != null) {
      final userModel = UserModel.fromFirebaseUser(firebaseUser);
      state = AuthStateModel.authenticated(userModel);
    } else {
      state = AuthStateModel.unauthenticated();
    }
  }

  Future<void> signOut() async {
    state = AuthStateModel.loading();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      state = AuthStateModel.error('Failed to sign out: $e');
    }
  }

  void setLoading() {
    state = AuthStateModel.loading();
  }

  void setError(String message) {
    state = AuthStateModel.error(message);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthStateModel>(
  (ref) => AuthStateNotifier(),
);

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});
