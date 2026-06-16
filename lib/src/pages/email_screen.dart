import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/email_auth_model.dart';
import '../theme/auth_theme.dart';
import '../widgets/tc_footer.dart';

/// Form field name constants — avoids magic strings across the form.
class _F {
  static const email = 'email';
  static const password = 'password';
  static const confirmPassword = 'confirmPassword';
}

/// Email authentication screen — handles sign in, sign up, and forgot password
/// in a single widget by switching [EmailAuthMode].
///
/// All Firebase operations are delegated to [EmailAuthNotifier] — this screen
/// only calls notifier methods and reacts to state.
///
/// Parameters:
/// - [phoneEnabled] — shows "Or continue with Phone" link at the bottom.
/// - [termsRoute] — route path for your Terms & Conditions page.
/// - [privacyRoute] — route path for your Privacy Policy page.
class AuthEmail extends ConsumerStatefulWidget {
  /// Shows "Or continue with Phone" link when `true`.
  /// Requires `/phone` to be registered in your router.
  final bool phoneEnabled;

  /// Route path for the Terms & Conditions page. Defaults to `'/terms'`.
  final String termsRoute;

  /// Route path for the Privacy Policy page. Defaults to `'/privacy'`.
  final String privacyRoute;

  const AuthEmail({
    super.key,
    this.phoneEnabled = false,
    this.termsRoute = '/terms',
    this.privacyRoute = '/privacy',
  });

  @override
  ConsumerState<AuthEmail> createState() => _AuthEmailState();
}

class _AuthEmailState extends ConsumerState<AuthEmail> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _submit(EmailAuthMode mode) async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    ref.read(emailAuthProvider.notifier).clearError();

    final values = _formKey.currentState!.value;
    final email = (values[_F.email] as String).trim();
    final password = (values[_F.password] as String? ?? '');

    switch (mode) {
      case EmailAuthMode.signIn:
        await ref.read(emailAuthProvider.notifier).signIn(email, password);
        // authStateProvider updates via Firebase stream — no manual navigation.
        if (mounted && ref.read(emailAuthProvider).error == null) {
          context.go('/home');
        }
      case EmailAuthMode.signUp:
        await ref.read(emailAuthProvider.notifier).signUp(email, password);
        if (mounted && ref.read(emailAuthProvider).error == null) {
          context.go('/home');
        }
      case EmailAuthMode.forgotPassword:
        await ref.read(emailAuthProvider.notifier).sendPasswordReset(email);
        // Auto-navigate back to sign in after 3 seconds on success.
        if (mounted && ref.read(emailAuthProvider).isPasswordResetSent) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _switchMode(EmailAuthMode.signIn);
            }
          });
        }
    }
  }

  void _switchMode(EmailAuthMode mode) {
    ref.read(emailAuthProvider.notifier).setMode(mode);
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final emailState = ref.watch(emailAuthProvider);
    final mode = emailState.mode;
    final isLoading = emailState.isLoading;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AuthColors.white,
      appBar: AppBar(
        title: Text(_appBarTitle(mode), style: AuthTextStyles.headlineS),
        leading: mode == EmailAuthMode.forgotPassword
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _switchMode(EmailAuthMode.signIn),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h + keyboardHeight),
        child: FormBuilder(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),
              Text(_subtitle(mode), style: AuthTextStyles.bodyL),
              SizedBox(height: 32.h),

              // ── Reset sent banner ──────────────────────────────────
              if (mode == EmailAuthMode.forgotPassword &&
                  emailState.isPasswordResetSent) ...[
                _ResetSentBanner(email: emailState.email ?? ''),
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    'Returning to sign in...',
                    style:
                        AuthTextStyles.caption.copyWith(color: AuthColors.black50),
                  ),
                ),
              ] else ...[

                // ── Email field ────────────────────────────────────
                FormBuilderTextField(
                  name: _F.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: mode == EmailAuthMode.forgotPassword
                      ? TextInputAction.done
                      : TextInputAction.next,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'Email is required'),
                    FormBuilderValidators.email(
                        errorText: 'Enter a valid email'),
                  ]),
                  onSubmitted: mode == EmailAuthMode.forgotPassword
                      ? (_) => _submit(mode)
                      : null,
                ),

                // ── Password fields (not for forgot password) ──────
                if (mode != EmailAuthMode.forgotPassword) ...[
                  SizedBox(height: 16.h),
                  FormBuilderTextField(
                    name: _F.password,
                    obscureText: _obscurePassword,
                    textInputAction: mode == EmailAuthMode.signUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AuthColors.black50,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Password is required'),
                      FormBuilderValidators.minLength(6,
                          errorText: 'Password must be at least 6 characters'),
                    ]),
                    onSubmitted: mode == EmailAuthMode.signIn
                        ? (_) => _submit(mode)
                        : null,
                  ),

                  // ── Confirm password (sign up only) ──────────────
                  if (mode == EmailAuthMode.signUp) ...[
                    SizedBox(height: 16.h),
                    FormBuilderTextField(
                      name: _F.confirmPassword,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AuthColors.black50,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        final pw = _formKey
                            .currentState?.fields[_F.password]?.value
                            as String?;
                        if (value != pw) return 'Passwords do not match';
                        return null;
                      },
                      onSubmitted: (_) => _submit(mode),
                    ),
                  ],

                  // ── Forgot password link (sign in only) ──────────
                  if (mode == EmailAuthMode.signIn) ...[
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () =>
                                _switchMode(EmailAuthMode.forgotPassword),
                        child: Text(
                          'Forgot password?',
                          style: AuthTextStyles.labelM
                              .copyWith(color: AuthColors.black50),
                        ),
                      ),
                    ),
                  ],
                ],

                // ── Firebase error ─────────────────────────────────
                if (emailState.error != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    emailState.error!,
                    style: AuthTextStyles.bodyM
                        .copyWith(color: AuthColors.error),
                  ),
                ],

                SizedBox(height: 32.h),

                // ── Submit button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _submit(mode),
                    child: isLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : Text(_buttonLabel(mode)),
                  ),
                ),

                SizedBox(height: 24.h),

                // ── Sign in / Sign up toggle ───────────────────────
                if (mode != EmailAuthMode.forgotPassword)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mode == EmailAuthMode.signIn
                              ? 'Don\'t have an account? '
                              : 'Already have an account? ',
                          style: AuthTextStyles.bodyM,
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => _switchMode(
                                    mode == EmailAuthMode.signIn
                                        ? EmailAuthMode.signUp
                                        : EmailAuthMode.signIn,
                                  ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            mode == EmailAuthMode.signIn
                                ? 'Sign Up'
                                : 'Sign In',
                            style: AuthTextStyles.labelM
                                .copyWith(color: AuthColors.yellow),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Phone toggle ───────────────────────────────────
                if (widget.phoneEnabled &&
                    mode != EmailAuthMode.forgotPassword) ...[
                  SizedBox(height: 8.h),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Or continue with ', style: AuthTextStyles.bodyM),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.go('/phone'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Phone',
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
            ],
          ),
        ),
      ),
    );
  }

  String _appBarTitle(EmailAuthMode mode) => switch (mode) {
        EmailAuthMode.signIn => 'Sign In',
        EmailAuthMode.signUp => 'Create Account',
        EmailAuthMode.forgotPassword => 'Reset Password',
      };

  String _subtitle(EmailAuthMode mode) => switch (mode) {
        EmailAuthMode.signIn => 'Welcome back! Sign in to continue.',
        EmailAuthMode.signUp => 'Create an account to get started.',
        EmailAuthMode.forgotPassword =>
          'Enter your email and we\'ll send you a reset link.',
      };

  String _buttonLabel(EmailAuthMode mode) => switch (mode) {
        EmailAuthMode.signIn => 'Sign In',
        EmailAuthMode.signUp => 'Create Account',
        EmailAuthMode.forgotPassword => 'Send Reset Link',
      };
}

// ── Reset sent banner ──────────────────────────────────────────────────────

class _ResetSentBanner extends StatelessWidget {
  final String email;
  const _ResetSentBanner({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AuthColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AuthColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mark_email_read_outlined,
              color: AuthColors.success, size: 32.sp),
          SizedBox(height: 12.h),
          Text(
            'Reset link sent!',
            style: AuthTextStyles.titleM.copyWith(color: AuthColors.success),
          ),
          SizedBox(height: 4.h),
          Text(
            'Check your inbox at $email and follow the link to reset your password.',
            style: AuthTextStyles.bodyM,
          ),
        ],
      ),
    );
  }
}
