import 'package:flutter/foundation.dart';

import '_copy_with.dart';

/// Where the user is in the phone OTP flow.
enum PhoneAuthStatus {
  /// Nothing started yet.
  idle,

  /// `verifyPhoneNumber` is in flight — waiting for the SMS to go out.
  sendingCode,

  /// The SMS was sent. Waiting for the user to type the code.
  codeSent,

  /// `signInWithCredential` is in flight.
  verifying,

  /// Sign-in succeeded. The Firebase auth stream will follow.
  verified,

  /// The last step failed. [PhoneAuthModel.error] says why.
  error,
}

/// Immutable state for the phone OTP flow.
///
/// Owned by `PhoneAuthNotifier`, which also performs the Firebase calls — the
/// screens read this and call notifier methods, nothing more.
@immutable
class PhoneAuthModel {
  /// Where the flow currently is.
  final PhoneAuthStatus status;

  /// International phone number, e.g. `+919876543210`.
  final String? phoneNumber;

  /// Verification ID from the `codeSent` callback.
  final String? verificationId;

  /// Token that lets a resend skip a fresh reCAPTCHA. Null on the first send.
  final int? resendToken;

  /// User-facing failure message, or `null`.
  final String? error;

  /// Seconds left before "Resend code" becomes tappable.
  final int resendSeconds;

  const PhoneAuthModel({
    this.status = PhoneAuthStatus.idle,
    this.phoneNumber,
    this.verificationId,
    this.resendToken,
    this.error,
    this.resendSeconds = 0,
  });

  /// Initial empty state.
  factory PhoneAuthModel.initial() => const PhoneAuthModel();

  /// `true` while a network call is in flight.
  bool get isBusy =>
      status == PhoneAuthStatus.sendingCode ||
      status == PhoneAuthStatus.verifying;

  /// `true` once an SMS has been sent for the current number.
  bool get isCodeSent => verificationId != null;

  /// `true` when the resend button should be enabled.
  bool get canResend => resendSeconds == 0 && !isBusy && isCodeSent;

  /// Kept so 1.x call sites keep compiling. Prefer [isBusy].
  ///
  /// In 1.x this was a stored flag the screens set by hand, which is how the
  /// UI and the provider drifted apart. It is derived from [status] now.
  @Deprecated('Renamed to isBusy. Will be removed in 3.0.0.')
  bool get isLoading => isBusy;

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields accept an explicit `null` to clear them.
  PhoneAuthModel copyWith({
    PhoneAuthStatus? status,
    Object? phoneNumber = kUnset,
    Object? verificationId = kUnset,
    Object? resendToken = kUnset,
    Object? error = kUnset,
    int? resendSeconds,
  }) {
    return PhoneAuthModel(
      status: status ?? this.status,
      phoneNumber: pick<String>(phoneNumber, this.phoneNumber),
      verificationId: pick<String>(verificationId, this.verificationId),
      resendToken: pick<int>(resendToken, this.resendToken),
      error: pick<String>(error, this.error),
      resendSeconds: resendSeconds ?? this.resendSeconds,
    );
  }

  /// Returns a copy with [error] genuinely cleared.
  PhoneAuthModel clearError() => copyWith(error: null);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhoneAuthModel &&
        other.status == status &&
        other.phoneNumber == phoneNumber &&
        other.verificationId == verificationId &&
        other.resendToken == resendToken &&
        other.error == error &&
        other.resendSeconds == resendSeconds;
  }

  @override
  int get hashCode => Object.hash(
        status,
        phoneNumber,
        verificationId,
        resendToken,
        error,
        resendSeconds,
      );

  @override
  String toString() => 'PhoneAuthModel(status: $status, phone: $phoneNumber, '
      'codeSent: $isCodeSent, error: $error)';
}
