import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:phone_form_field/phone_form_field.dart';

import '../config/dot_auth_config.dart';
import '../models/phone_auth_model.dart';
import '../providers/phone_auth_provider.dart';
import '../theme/auth_theme.dart';
import '../widgets/error_line.dart';
import '../widgets/tc_footer.dart';

/// Phone number entry — the first step of the OTP flow.
///
/// Submitting runs the form validator, then hands the number to
/// [PhoneAuthNotifier.sendCode]. When the SMS goes out, the screen pushes the
/// OTP route from [dotAuthRoutesProvider]. No Firebase call happens here.
class AuthPhone extends ConsumerStatefulWidget {
  /// Shows an "email instead" link. The email route must be registered.
  final bool emailEnabled;

  /// Overrides the Terms & Conditions route for this screen's footer.
  final String? termsRoute;

  /// Overrides the Privacy Policy route for this screen's footer.
  final String? privacyRoute;

  const AuthPhone({
    super.key,
    this.emailEnabled = false,
    this.termsRoute,
    this.privacyRoute,
  });

  @override
  ConsumerState<AuthPhone> createState() => _AuthPhoneState();
}

class _AuthPhoneState extends ConsumerState<AuthPhone> {
  final _formKey = GlobalKey<FormState>();
  late final PhoneController _phoneController;

  @override
  void initState() {
    super.initState();
    final config = ref.read(dotAuthConfigProvider);
    _phoneController = PhoneController(
      initialValue: PhoneNumber(isoCode: config.defaultCountry, nsn: ''),
    );
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    // Editing the number should retire the previous failure.
    ref.read(phoneAuthProvider.notifier).clearError();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // The validator is the gate. Without a Form around the field it only
    // paints red text — an empty number still reaches Firebase as "+91".
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneController.value;
    if (!phone.isValid(type: PhoneNumberType.mobile)) return;

    await ref.read(phoneAuthProvider.notifier).sendCode(phone.international);
  }

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(dotAuthRoutesProvider);
    final phoneState = ref.watch(phoneAuthProvider);
    final isBusy = phoneState.isBusy;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    // Move on only when the SMS has actually been sent.
    ref.listen<PhoneAuthModel>(phoneAuthProvider, (previous, next) {
      final justSent = previous?.status != PhoneAuthStatus.codeSent &&
          next.status == PhoneAuthStatus.codeSent;
      if (!justSent) return;
      if (!context.mounted) return;
      context.push(routes.otp);
    });

    return Scaffold(
      backgroundColor: AuthColors.white,
      appBar: AppBar(title: const Text('Enter your mobile number')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h + keyboardInset),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                Text(
                  'We will send a 6-digit code by SMS.',
                  style: AuthTextStyles.bodyL,
                ),
                SizedBox(height: 32.h),

                PhoneFormField(
                  controller: _phoneController,
                  enabled: !isBusy,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    hintText: '98765 43210',
                  ),
                  validator: PhoneValidator.compose([
                    PhoneValidator.required(context),
                    PhoneValidator.validMobile(context),
                  ]),
                  onSubmitted: (_) => _submit(),
                ),

                if (phoneState.error != null) ...[
                  SizedBox(height: 12.h),
                  AuthErrorLine(message: phoneState.error!),
                ],

                SizedBox(height: 32.h),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isBusy ? null : _submit,
                    child: isBusy
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AuthColors.black,
                            ),
                          )
                        : const Text('Send code'),
                  ),
                ),

                if (widget.emailEnabled) ...[
                  SizedBox(height: 24.h),
                  Center(
                    child: TextButton(
                      onPressed: isBusy ? null : () => context.go(routes.email),
                      child: Text(
                        'Use email instead',
                        style: AuthTextStyles.link,
                      ),
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
        ),
      ),
    );
  }
}
