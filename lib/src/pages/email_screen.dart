import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../config/dot_auth_config.dart';
import '../models/email_auth_model.dart';
import '../providers/email_auth_provider.dart';
import '../theme/auth_theme.dart';
import '../widgets/error_line.dart';
import '../widgets/tc_footer.dart';

/// Field names, kept in one place so the form and its validators agree.
class _Field {
  static const email = 'email';
  static const password = 'password';
  static const confirmPassword = 'confirmPassword';
}

/// Email sign in, sign up, and password reset in one screen.
///
/// Firebase work is delegated to [EmailAuthNotifier]. On success the Firebase
/// auth stream updates `authStateProvider` and your router's redirect takes the
/// user home — this screen never navigates there itself, so a stale error can
/// never strand a signed-in user on the login form.
class AuthEmail extends ConsumerStatefulWidget {
  /// Shows a "mobile number instead" link. The phone route must be registered.
  final bool phoneEnabled;

  /// Overrides the Terms & Conditions route for this screen's footer.
  final String? termsRoute;

  /// Overrides the Privacy Policy route for this screen's footer.
  final String? privacyRoute;

  const AuthEmail({
    super.key,
    this.phoneEnabled = false,
    this.termsRoute,
    this.privacyRoute,
  });

  @override
  ConsumerState<AuthEmail> createState() => _AuthEmailState();
}

class _AuthEmailState extends ConsumerState<AuthEmail> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _submit(EmailAuthMode mode) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final values = _formKey.currentState!.value;
    final email = (values[_Field.email] as String).trim();
    final password = values[_Field.password] as String? ?? '';
    final notifier = ref.read(emailAuthProvider.notifier);

    switch (mode) {
      case EmailAuthMode.signIn:
        await notifier.signIn(email, password);
      case EmailAuthMode.signUp:
        await notifier.signUp(email, password);
      case EmailAuthMode.forgotPassword:
        await notifier.sendPasswordReset(email);
    }
  }

  void _switchMode(EmailAuthMode mode) {
    ref.read(emailAuthProvider.notifier).setMode(mode);
    _formKey.currentState?.reset();
  }

  /// Re-checks the confirmation field when the password above it changes,
  /// so "Passwords do not match" clears the moment they do.
  void _revalidateConfirm() {
    _formKey.currentState?.fields[_Field.confirmPassword]?.validate();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(dotAuthConfigProvider);
    final routes = config.routes;
    final emailState = ref.watch(emailAuthProvider);
    final mode = emailState.mode;
    final isLoading = emailState.isLoading;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final showResetConfirmation =
        mode == EmailAuthMode.forgotPassword && emailState.isPasswordResetSent;

    return Scaffold(
      backgroundColor: AuthColors.white,
      appBar: AppBar(
        title: Text(_title(mode)),
        leading: mode == EmailAuthMode.forgotPassword
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to sign in',
                onPressed: () => _switchMode(EmailAuthMode.signIn),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h + keyboardInset),
          child: FormBuilder(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),

                if (showResetConfirmation) ...[
                  _ResetSentBanner(email: emailState.email ?? ''),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _switchMode(EmailAuthMode.signIn),
                      child: const Text('Back to sign in'),
                    ),
                  ),
                ] else ...[
                  Text(_subtitle(mode), style: AuthTextStyles.bodyL),
                  SizedBox(height: 32.h),

                  // ── Email ──────────────────────────────────────────
                  FormBuilderTextField(
                    name: _Field.email,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: mode == EmailAuthMode.forgotPassword
                        ? TextInputAction.done
                        : TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'Enter your email address.',
                      ),
                      FormBuilderValidators.email(
                        errorText: 'That does not look like an email address.',
                      ),
                    ]),
                    onSubmitted: mode == EmailAuthMode.forgotPassword
                        ? (_) => _submit(mode)
                        : null,
                  ),

                  // ── Password ───────────────────────────────────────
                  if (mode != EmailAuthMode.forgotPassword) ...[
                    SizedBox(height: 16.h),
                    FormBuilderTextField(
                      name: _Field.password,
                      enabled: !isLoading,
                      obscureText: _obscurePassword,
                      autofillHints: [
                        mode == EmailAuthMode.signUp
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      textInputAction: mode == EmailAuthMode.signUp
                          ? TextInputAction.next
                          : TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AuthColors.black50,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Enter your password.',
                        ),
                        FormBuilderValidators.minLength(
                          config.minPasswordLength,
                          errorText: 'Use at least '
                              '${config.minPasswordLength} characters.',
                        ),
                      ]),
                      onChanged: mode == EmailAuthMode.signUp
                          ? (_) => _revalidateConfirm()
                          : null,
                      onSubmitted: mode == EmailAuthMode.signIn
                          ? (_) => _submit(mode)
                          : null,
                    ),

                    // ── Confirm password ─────────────────────────────
                    if (mode == EmailAuthMode.signUp) ...[
                      SizedBox(height: 16.h),
                      FormBuilderTextField(
                        name: _Field.confirmPassword,
                        enabled: !isLoading,
                        obscureText: _obscureConfirm,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirm
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AuthColors.black50,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final password = _formKey
                              .currentState?.fields[_Field.password]?.value
                              as String?;
                          if (value == null || value.isEmpty) {
                            return 'Retype your password.';
                          }
                          if (value != password) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                        onSubmitted: (_) => _submit(mode),
                      ),
                    ],

                    // ── Forgot password ──────────────────────────────
                    if (mode == EmailAuthMode.signIn) ...[
                      SizedBox(height: 4.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () =>
                                  _switchMode(EmailAuthMode.forgotPassword),
                          child: Text(
                            'Forgot password?',
                            style: AuthTextStyles.link,
                          ),
                        ),
                      ),
                    ],
                  ],

                  if (emailState.error != null) ...[
                    SizedBox(height: 12.h),
                    AuthErrorLine(message: emailState.error!),
                  ],

                  SizedBox(height: 32.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _submit(mode),
                      child: isLoading
                          ? SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AuthColors.black,
                              ),
                            )
                          : Text(_buttonLabel(mode)),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  if (mode != EmailAuthMode.forgotPassword)
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            mode == EmailAuthMode.signIn
                                ? 'No account yet? '
                                : 'Already have an account? ',
                            style: AuthTextStyles.bodyM,
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => _switchMode(
                                      mode == EmailAuthMode.signIn
                                          ? EmailAuthMode.signUp
                                          : EmailAuthMode.signIn,
                                    ),
                            child: Text(
                              mode == EmailAuthMode.signIn
                                  ? 'Create one'
                                  : 'Sign in',
                              style: AuthTextStyles.link,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (widget.phoneEnabled &&
                      mode != EmailAuthMode.forgotPassword) ...[
                    SizedBox(height: 8.h),
                    Center(
                      child: TextButton(
                        onPressed:
                            isLoading ? null : () => context.go(routes.phone),
                        child: Text(
                          'Use mobile number instead',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(EmailAuthMode mode) => switch (mode) {
        EmailAuthMode.signIn => 'Sign in',
        EmailAuthMode.signUp => 'Create account',
        EmailAuthMode.forgotPassword => 'Reset password',
      };

  String _subtitle(EmailAuthMode mode) => switch (mode) {
        EmailAuthMode.signIn => 'Sign in to continue.',
        EmailAuthMode.signUp => 'Create an account to get started.',
        EmailAuthMode.forgotPassword =>
          'Enter your email and we will send a reset link.',
      };

  String _buttonLabel(EmailAuthMode mode) => switch (mode) {
        EmailAuthMode.signIn => 'Sign in',
        EmailAuthMode.signUp => 'Create account',
        EmailAuthMode.forgotPassword => 'Send reset link',
      };
}

class _ResetSentBanner extends StatelessWidget {
  final String email;

  const _ResetSentBanner({required this.email});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AuthColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AuthColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              color: AuthColors.success,
              size: 32.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              'Reset link sent',
              style: AuthTextStyles.titleM.copyWith(color: AuthColors.success),
            ),
            SizedBox(height: 4.h),
            Text(
              'Open the link we sent to $email to choose a new password. '
              'If it has not arrived in a minute, check your spam folder.',
              style: AuthTextStyles.bodyM,
            ),
          ],
        ),
      ),
    );
  }
}
