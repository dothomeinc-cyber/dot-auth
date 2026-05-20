class PhoneAuthModel {
  final String? phoneNumber;
  final String? verificationId;
  final String? otpCode;
  final bool isCodeSent;
  final bool isLoading;
  final String? error;
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

  factory PhoneAuthModel.initial() {
    return const PhoneAuthModel(
      phoneNumber: null,
      verificationId: null,
      otpCode: null,
      isCodeSent: false,
      isLoading: false,
      error: null,
      resendToken: null,
    );
  }

  factory PhoneAuthModel.loading() {
    return const PhoneAuthModel(
      phoneNumber: null,
      verificationId: null,
      otpCode: null,
      isCodeSent: false,
      isLoading: true,
      error: null,
      resendToken: null,
    );
  }

  factory PhoneAuthModel.codeSent({
    required String phoneNumber,
    required String verificationId,
    int? resendToken,
  }) {
    return PhoneAuthModel(
      phoneNumber: phoneNumber,
      verificationId: verificationId,
      isCodeSent: true,
      isLoading: false,
      error: null,
      resendToken: resendToken,
    );
  }

  factory PhoneAuthModel.error(String errorMessage) {
    return PhoneAuthModel(
      phoneNumber: null,
      verificationId: null,
      isCodeSent: false,
      isLoading: false,
      error: errorMessage,
      resendToken: null,
    );
  }

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

  PhoneAuthModel clearError() {
    return copyWith(error: null);
  }

  PhoneAuthModel setOtp(String otp) {
    return copyWith(otpCode: otp);
  }
}
