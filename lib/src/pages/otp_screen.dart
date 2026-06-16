import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_theme.dart';

/// OTP verification screen — entered after [AuthPhone] sends the SMS.
///
/// Features:
/// - Android auto-verification via Firebase's `verificationCompleted`
///   callback (fires automatically when Play Services detects the SMS —
///   no Pinput-level autofill config needed)
/// - iOS QuickType bar autofill via [AutofillHints.oneTimeCode]
/// - 30-second resend countdown
/// - Verification ID and resend token read from [phoneAuthProvider]
/// - Pin cleared automatically on failed verification
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _canResend = false;

  /// Controller allows programmatic clear on failed verification.
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _verifyOtp(String otpCode) async {
    if (otpCode.length != 6) return;

    final verificationId = ref.read(phoneAuthProvider).verificationId;

    if (verificationId == null) {
      setState(() => _errorMessage = 'Verification failed. Please try again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        ref.read(phoneAuthProvider.notifier).reset();
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      _pinController.clear();
      setState(() {
        _errorMessage = e.message ?? 'Invalid verification code';
        _isLoading = false;
      });
    } catch (e) {
      _pinController.clear();
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    final phoneAuthState = ref.read(phoneAuthProvider);
    final phoneNumber = phoneAuthState.phoneNumber;

    if (phoneNumber == null) {
      context.go('/phone');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    ref.read(phoneAuthProvider.notifier).setLoading(true);
    ref.read(phoneAuthProvider.notifier).clearError();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        // resendToken may be null on first resend — Firebase handles gracefully.
        forceResendingToken: phoneAuthState.resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) context.go('/home');
        },
        verificationFailed: (FirebaseAuthException e) {
          ref
              .read(phoneAuthProvider.notifier)
              .setError(e.message ?? 'Failed to resend code');
          setState(() {
            _errorMessage = e.message ?? 'Failed to resend code';
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? newResendToken) {
          // Store the fresh verificationId and resendToken in the provider.
          ref
              .read(phoneAuthProvider.notifier)
              .setVerificationData(verificationId, newResendToken);
          setState(() => _isLoading = false);
          _pinController.clear();
          _startTimer();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Code resent successfully!',
                  style: AuthTextStyles.bodyM.copyWith(color: AuthColors.white),
                ),
                backgroundColor: AuthColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneAuthState = ref.watch(phoneAuthProvider);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final defaultPinTheme = PinTheme(
      width: 56.w,
      height: 56.h,
      textStyle: AuthTextStyles.headlineM.copyWith(color: AuthColors.black),
      decoration: BoxDecoration(
        color: AuthColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AuthColors.black15),
      ),
    );

    return Scaffold(
      backgroundColor: AuthColors.white,
      appBar: AppBar(
        title: Text('Enter Verification Code', style: AuthTextStyles.headlineS),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h + keyboardHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40.h),
            Text('We\'ve sent a 6-digit code to', style: AuthTextStyles.bodyL),
            SizedBox(height: 4.h),
            Text(
              phoneAuthState.phoneNumber ?? '',
              style:
                  AuthTextStyles.titleM.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 32.h),

            Center(
              child: Pinput(
                length: 6,
                controller: _pinController,

                // iOS — shows code in QuickType bar above keyboard.
                autofillHints: const [AutofillHints.oneTimeCode],
                keyboardType: TextInputType.number,

                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border:
                        Border.all(color: AuthColors.black, width: 1.5.w),
                  ),
                ),
                errorPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AuthColors.error),
                  ),
                ),
                onCompleted: _verifyOtp,
                pinAnimationType: PinAnimationType.fade,
                enabled: !_isLoading,
              ),
            ),

            if (_errorMessage != null) ...[
              SizedBox(height: 16.h),
              Center(
                child: Text(
                  _errorMessage!,
                  style:
                      AuthTextStyles.bodyM.copyWith(color: AuthColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            SizedBox(height: 32.h),

            Center(
              child: Column(
                children: [
                  if (!_canResend && _secondsRemaining > 0)
                    Text(
                      'Resend code in $_secondsRemaining seconds',
                      style: AuthTextStyles.bodyM
                          .copyWith(color: AuthColors.black50),
                    ),
                  if (_canResend)
                    TextButton(
                      onPressed: _isLoading ? null : _resendCode,
                      child: Text(
                        'Resend Code',
                        style: AuthTextStyles.labelM
                            .copyWith(color: AuthColors.yellow),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
