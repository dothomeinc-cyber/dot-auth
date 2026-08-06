import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/dot_auth_config.dart';
import '../models/phone_auth_model.dart';
import '../utils/auth_error_mapper.dart';
import 'firebase_providers.dart';

/// Owns the phone OTP flow: sending the SMS, resending it, verifying the code,
/// and the resend cooldown.
///
/// Every Firebase call for phone auth lives here. Screens read [state] and call
/// these methods — they never touch [FirebaseAuth] directly, which keeps the
/// flow testable and stops the UI and the provider from disagreeing about
/// whether something is loading.
class PhoneAuthNotifier extends Notifier<PhoneAuthModel> {
  Timer? _cooldownTimer;
  bool _disposed = false;

  // Cached at build time. Firebase callbacks can fire long after the provider
  // is gone, and ref.read on a disposed provider throws.
  late FirebaseAuth _auth;
  late DotAuthConfig _config;

  @override
  PhoneAuthModel build() {
    _auth = ref.read(firebaseAuthProvider);
    _config = ref.read(dotAuthConfigProvider);
    ref.onDispose(() {
      _disposed = true;
      _cooldownTimer?.cancel();
    });
    return PhoneAuthModel.initial();
  }

  /// Firebase callbacks can fire after the provider is gone. Writing to
  /// [state] then throws, so every async path goes through this.
  void _emit(PhoneAuthModel next) {
    if (_disposed) return;
    state = next;
  }

  /// Sends an SMS code to [phoneNumber], which must be in international
  /// format (`+919876543210`).
  Future<void> sendCode(String phoneNumber) async {
    _emit(state.copyWith(
      status: PhoneAuthStatus.sendingCode,
      phoneNumber: phoneNumber,
      verificationId: null,
      resendToken: null,
      error: null,
      resendSeconds: 0,
    ));
    await _verify(phoneNumber, null);
  }

  /// Requests a fresh SMS for the number already in [state].
  ///
  /// Does nothing while the cooldown is running.
  Future<void> resendCode() async {
    final phoneNumber = state.phoneNumber;
    if (phoneNumber == null) return;
    if (!state.canResend) return;

    _emit(state.copyWith(
      status: PhoneAuthStatus.sendingCode,
      error: null,
    ));
    await _verify(phoneNumber, state.resendToken);
  }

  Future<void> _verify(String phoneNumber, int? resendToken) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: _config.smsAutoRetrievalTimeout,
        forceResendingToken: resendToken,
        verificationCompleted: _onAutoVerified,
        verificationFailed: (e) => _emit(state.copyWith(
          status: PhoneAuthStatus.error,
          error: mapAuthError(e.code),
        )),
        codeSent: (verificationId, token) {
          _emit(state.copyWith(
            status: PhoneAuthStatus.codeSent,
            verificationId: verificationId,
            resendToken: token,
            error: null,
          ));
          _startCooldown();
        },
        // Android's SMS auto-retrieval window closing is part of the happy
        // path, not a failure. Keep the verification ID and say nothing.
        codeAutoRetrievalTimeout: (verificationId) => _emit(
          state.copyWith(verificationId: verificationId),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _emit(state.copyWith(
        status: PhoneAuthStatus.error,
        error: mapAuthError(e.code),
      ));
    } catch (_) {
      _emit(state.copyWith(
        status: PhoneAuthStatus.error,
        error: 'Could not send the code. Try again.',
      ));
    }
  }

  /// Android instant verification — Play Services read the SMS for us.
  Future<void> _onAutoVerified(PhoneAuthCredential credential) async {
    _emit(state.copyWith(status: PhoneAuthStatus.verifying, error: null));
    try {
      await _auth.signInWithCredential(credential);
      _cooldownTimer?.cancel();
      _emit(state.copyWith(status: PhoneAuthStatus.verified, error: null));
    } on FirebaseAuthException catch (e) {
      _emit(state.copyWith(
        status: PhoneAuthStatus.error,
        error: mapAuthError(e.code),
      ));
    }
  }

  /// Verifies the [smsCode] the user typed and signs them in.
  Future<void> verifyOtp(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      _emit(state.copyWith(
        status: PhoneAuthStatus.error,
        error: 'This code expired. Request a new one.',
      ));
      return;
    }

    _emit(state.copyWith(status: PhoneAuthStatus.verifying, error: null));
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      _cooldownTimer?.cancel();
      _emit(state.copyWith(status: PhoneAuthStatus.verified, error: null));
    } on FirebaseAuthException catch (e) {
      _emit(state.copyWith(
        status: PhoneAuthStatus.error,
        error: mapAuthError(e.code),
      ));
    } catch (_) {
      _emit(state.copyWith(
        status: PhoneAuthStatus.error,
        error: 'Could not verify the code. Try again.',
      ));
    }
  }

  /// Clears the current error and returns to whichever step the user is on.
  void clearError() {
    if (state.error == null) return;
    _emit(state.copyWith(
      status: state.isCodeSent
          ? PhoneAuthStatus.codeSent
          : PhoneAuthStatus.idle,
      error: null,
    ));
  }

  /// Wipes the flow — call when leaving it or after signing out.
  void reset() {
    _cooldownTimer?.cancel();
    _emit(PhoneAuthModel.initial());
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    final seconds = _config.resendCooldown.inSeconds;
    _emit(state.copyWith(resendSeconds: seconds));
    if (seconds <= 0) return;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      final remaining = state.resendSeconds - 1;
      if (remaining <= 0) timer.cancel();
      _emit(state.copyWith(resendSeconds: remaining < 0 ? 0 : remaining));
    });
  }
}

/// Phone OTP flow state and actions.
final phoneAuthProvider =
    NotifierProvider<PhoneAuthNotifier, PhoneAuthModel>(
  PhoneAuthNotifier.new,
);
