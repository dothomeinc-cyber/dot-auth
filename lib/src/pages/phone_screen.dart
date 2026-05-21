import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_theme.dart';

class AuthPhone extends ConsumerStatefulWidget {
  const AuthPhone({super.key});

  @override
  ConsumerState<AuthPhone> createState() =>
      _AuthPhoneState();
}

class _AuthPhoneState extends ConsumerState<AuthPhone> {
  final PhoneController _phoneController = PhoneController(
    initialValue:
        const PhoneNumber(isoCode: IsoCode.IN, nsn: ''),
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final phoneNumber =
        _phoneController.value.international;

    if (phoneNumber.isEmpty) {
      ref
          .read(phoneAuthProvider.notifier)
          .setError('Please enter a valid phone number');
      return;
    }

    ref.read(phoneAuthProvider.notifier).setLoading(true);
    ref.read(phoneAuthProvider.notifier).clearError();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted:
            (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance
              .signInWithCredential(credential);
          if (mounted) {
            ref
                .read(phoneAuthProvider.notifier)
                .setPhoneNumber(phoneNumber);
            if (mounted) {
              context.go('/home');
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          ref
              .read(phoneAuthProvider.notifier)
              .setError(e.message ?? 'Verification failed');
        },
        codeSent:
            (String verificationId, int? resendToken) {
          ref
              .read(phoneAuthProvider.notifier)
              .setPhoneNumber(phoneNumber);
          ref
              .read(phoneAuthProvider.notifier)
              .setVerificationId(verificationId);
          if (mounted) {
            context.go('/otp');
          }
        },
        codeAutoRetrievalTimeout:
            (String verificationId) {},
      );
    } catch (e) {
      ref
          .read(phoneAuthProvider.notifier)
          .setError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneAuthState = ref.watch(phoneAuthProvider);

    return Scaffold(
      backgroundColor: AuthColors.white,
      appBar: AppBar(
        title: Text(
          'Enter Phone Number',
          style: AuthTextStyles.headlineS,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
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
              autovalidateMode:
                  AutovalidateMode.onUserInteraction,
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: phoneAuthState.isLoading
                    ? null
                    : _sendVerificationCode,
                child: phoneAuthState.isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child:
                            const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Send Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
