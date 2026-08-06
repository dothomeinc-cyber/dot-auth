import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../config/dot_auth_config.dart';
import '../models/phone_auth_model.dart';
import '../providers/phone_auth_provider.dart';
import '../theme/auth_theme.dart';
import '../widgets/error_line.dart';

/// OTP verification, reached after [AuthPhone] sends the SMS.
///
/// Everything — the verification ID, the resend token, the cooldown, the
/// Firebase calls — lives in [PhoneAuthNotifier]. This screen reads state and
/// calls methods, so a rebuild or a hot reload can't desync it.
///
/// Android instant verification is handled inside the notifier's
/// `verificationCompleted` callback; iOS gets the code offered in the QuickType
/// bar via [AutofillHints.oneTimeCode].
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Landing here without a verification ID — a deep link, or a hot restart
    // that wiped the flow — leaves a screen that can never succeed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(phoneAuthProvider).isCodeSent) return;
      _leave();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _leave() {
    final routes = ref.read(dotAuthRoutesProvider);
    if (context.canPop()) {
      context.pop();
      return;
    }
    // Reached via `go`, so there is no stack to pop back through.
    context.go(routes.phone);
  }

  Future<void> _verify(String code) async {
    FocusScope.of(context).unfocus();
    await ref.read(phoneAuthProvider.notifier).verifyOtp(code);
  }

  Future<void> _resend() async {
    await ref.read(phoneAuthProvider.notifier).resendCode();
    if (!mounted) return;
    _pinController.clear();
    _pinFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(dotAuthConfigProvider);
    final phoneState = ref.watch(phoneAuthProvider);
    final isBusy = phoneState.isBusy;
    final hasError = phoneState.error != null;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    // A failed code should clear the boxes so the user can just retype.
    ref.listen<PhoneAuthModel>(phoneAuthProvider, (previous, next) {
      final justFailed = previous?.error == null && next.error != null;
      if (!justFailed) return;
      if (!mounted) return;
      _pinController.clear();
      _pinFocus.requestFocus();
    });

    final defaultPinTheme = PinTheme(
      width: 48.w,
      height: 56.h,
      textStyle: AuthTextStyles.headlineM,
      decoration: BoxDecoration(
        color: AuthColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AuthColors.black15),
      ),
    );

    return Scaffold(
      backgroundColor: AuthColors.white,
      appBar: AppBar(
        title: const Text('Enter the code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to mobile number',
          onPressed: isBusy ? null : _leave,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h + keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),
              Text(
                'We sent a ${config.otpLength}-digit code to',
                style: AuthTextStyles.bodyL,
              ),
              SizedBox(height: 4.h),
              Text(
                phoneState.phoneNumber ?? '',
                style: AuthTextStyles.titleM.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 32.h),

              Center(
                child: Pinput(
                  length: config.otpLength,
                  controller: _pinController,
                  focusNode: _pinFocus,
                  autofocus: true,
                  enabled: !isBusy,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: AuthColors.black, width: 1.5.w),
                    ),
                  ),
                  errorPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: AuthColors.error),
                    ),
                  ),
                  // Without this the errorPinTheme above never renders.
                  forceErrorState: hasError,
                  pinAnimationType: PinAnimationType.fade,
                  onCompleted: _verify,
                ),
              ),

              if (hasError) ...[
                SizedBox(height: 16.h),
                AuthErrorLine(message: phoneState.error!, centered: true),
              ],

              SizedBox(height: 24.h),

              // Typing all six digits submits automatically, but an explicit
              // control is needed for switch access and for anyone who pastes.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : () {
                          final code = _pinController.text;
                          if (code.length != config.otpLength) return;
                          _verify(code);
                        },
                  child: isBusy
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AuthColors.black,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),

              SizedBox(height: 24.h),

              Center(
                child: phoneState.canResend
                    ? TextButton(
                        onPressed: _resend,
                        child: Text('Resend code', style: AuthTextStyles.link),
                      )
                    : Text(
                        'Resend code in ${phoneState.resendSeconds}s',
                        style: AuthTextStyles.bodyM.copyWith(
                          color: AuthColors.black50,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
