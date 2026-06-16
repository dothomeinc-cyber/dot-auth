/// Immutable state for the phone OTP verification flow.
///
/// Managed by [PhoneAuthNotifier] and exposed via [phoneAuthProvider].
class PhoneAuthModel {
  /// International phone number e.g. `+919876543210`.
  final String? phoneNumber;

  /// Firebase verification ID received after [FirebaseAuth.verifyPhoneNumber].
  final String? verificationId;

  /// OTP code typed by the user.
  final String? otpCode;

  /// `true` after Firebase has sent the SMS code.
  final bool isCodeSent;

  /// `true` while a network operation is in progress.
  final bool isLoading;

  /// Human-readable error message, or `null` if no error.
  final String? error;

  /// Token used for force-resending the SMS without re-triggering reCAPTCHA.
  /// May be `null` on first send — Firebase handles this gracefully.
  final int? resendToken;

  const PhoneAuthModel({
    this.phoneNumber,
    this.verificationId,
    this.otpCode,
    this.isCodeSent = false,
    this.isLoading = false,
    this.error,
    this.resendToken,
  });

  /// Initial empty state.
  factory PhoneAuthModel.initial() => const PhoneAuthModel();

  /// Returns a copy with the given fields replaced.
  PhoneAuthModel copyWith({
    String? phoneNumber,
    String? verificationId,
    String? otpCode,
    bool? isCodeSent,
    bool? isLoading,
    String? error,
    int? resendToken,
  }) {
    return PhoneAuthModel(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      otpCode: otpCode ?? this.otpCode,
      isCodeSent: isCodeSent ?? this.isCodeSent,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      resendToken: resendToken ?? this.resendToken,
    );
  }

  /// Returns a copy with [error] set to `null`.
  PhoneAuthModel clearError() => copyWith(error: null);

  /// Returns a copy with [otpCode] set to [otp].
  PhoneAuthModel setOtp(String otp) => copyWith(otpCode: otp);
}
