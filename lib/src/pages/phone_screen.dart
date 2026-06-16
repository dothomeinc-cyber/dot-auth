import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_theme.dart';
import '../widgets/tc_footer.dart';

/// Phone number entry screen — first step of the OTP auth flow.
///
/// On submit, calls [FirebaseAuth.verifyPhoneNumber] and navigates to
/// [OtpScreen] at `/otp` when the SMS code is sent.
///
/// Parameters:
/// - [emailEnabled] — shows "Or continue with Email" link at the bottom.
/// - [termsRoute] — route path for your Terms & Conditions page.
/// - [privacyRoute] — route path for your Privacy Policy page.
class AuthPhone extends ConsumerStatefulWidget {
  /// Shows "Or continue with Email" link when `true`.
  /// Requires `/email` to be registered in your router.
  final bool emailEnabled;

  /// Route path for the Terms & Conditions page. Defaults to `'/terms'`.
  final String termsRoute;

  /// Route path for the Privacy Policy page. Defaults to `'/privacy'`.
  final String privacyRoute;

  const AuthPhone({
    super.key,
    this.emailEnabled = false,
    this.termsRoute = '/terms',
    this.privacyRoute = '/privacy',
  });

  @override
  ConsumerState<AuthPhone> createState() => _AuthPhoneState();
}

class _AuthPhoneState extends ConsumerState<AuthPhone> {
  final PhoneController _phoneController = PhoneController(
    initialValue: PhoneNumber(isoCode: IsoCode.IN, nsn: ''),
  );

  bool _verificationInProgress = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    if (_verificationInProgress) return;

    final phoneNumber = _phoneController.value.international;

    if (phoneNumber.isEmpty) {
      ref
          .read(phoneAuthProvider.notifier)
          .setError('Please enter a valid phone number');
      return;
    }

    setState(() => _verificationInProgress = true);
    ref.read(phoneAuthProvider.notifier).setLoading(true);
    ref.read(phoneAuthProvider.notifier).clearError();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android only — auto-signs in without user interaction.
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            ref.read(phoneAuthProvider.notifier).setPhoneNumber(phoneNumber);
            context.go('/home');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _verificationInProgress = false);
          ref
              .read(phoneAuthProvider.notifier)
              .setError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _verificationInProgress = false);
          ref.read(phoneAuthProvider.notifier).setPhoneNumber(phoneNumber);
          ref
              .read(phoneAuthProvider.notifier)
              .setVerificationData(verificationId, resendToken);
          if (mounted) context.go('/otp');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _verificationInProgress = false);
          ref
              .read(phoneAuthProvider.notifier)
              .setError('Timeout. Please try again.');
        },
      );
    } catch (e) {
      setState(() => _verificationInProgress = false);
      ref.read(phoneAuthProvider.notifier).setError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneAuthState = ref.watch(phoneAuthProvider);
    final isBusy = _verificationInProgress || phoneAuthState.isLoading;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AuthColors.white,
      appBar: AppBar(
        title: Text('Enter Phone Number', style: AuthTextStyles.headlineS),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h + keyboardHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40.h),
            Text(
              'We\'ll send you a verification code',
              style: AuthTextStyles.bodyL,
            ),
            SizedBox(height: 32.h),

            PhoneFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                errorText: phoneAuthState.error,
              ),
              validator: PhoneValidator.compose([
                PhoneValidator.required(context),
                PhoneValidator.validMobile(context),
              ]),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              enabled: !isBusy,
            ),

            SizedBox(height: 32.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy ? null : _sendVerificationCode,
                child: isBusy
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child:
                            const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Code'),
              ),
            ),

            // ── Email toggle ──────────────────────────────────────────
            if (widget.emailEnabled) ...[
              SizedBox(height: 24.h),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Or continue with ', style: AuthTextStyles.bodyM),
                    TextButton(
                      onPressed: isBusy ? null : () => context.go('/email'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Email',
                        style: AuthTextStyles.labelM
                            .copyWith(color: AuthColors.yellow),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 32.h),

            TcFooter(
              termsRoute: widget.termsRoute,
              privacyRoute: widget.privacyRoute,
            ),
          ],
        ),
      ),
    );
  }
}
