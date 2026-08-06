import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone_form_field/phone_form_field.dart';

/// Route paths dot_auth navigates to.
///
/// Nothing is hardcoded inside the screens — override this to match your app's
/// own paths:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     dotAuthConfigProvider.overrideWithValue(
///       const DotAuthConfig(
///         routes: DotAuthRoutes(home: '/dashboard'),
///       ),
///     ),
///   ],
///   child: const MyApp(),
/// )
/// ```
class DotAuthRoutes {
  /// Phone number entry screen.
  final String phone;

  /// OTP verification screen.
  final String otp;

  /// Email sign in / sign up / reset screen.
  final String email;

  /// Where to send the user once signed in.
  final String home;

  /// Terms & Conditions page.
  final String terms;

  /// Privacy Policy page.
  final String privacy;

  const DotAuthRoutes({
    this.phone = '/phone',
    this.otp = '/otp',
    this.email = '/email',
    this.home = '/home',
    this.terms = '/terms',
    this.privacy = '/privacy',
  });

  /// Paths an unauthenticated user may visit without being redirected.
  Set<String> get publicPaths => {phone, otp, email, terms, privacy};

  /// Paths an authenticated user should be pushed away from.
  Set<String> get signInPaths => {phone, otp, email};
}

/// Behavioural configuration for the dot_auth flows.
class DotAuthConfig {
  /// Route paths — see [DotAuthRoutes].
  final DotAuthRoutes routes;

  /// Country pre-selected in the phone field.
  final IsoCode defaultCountry;

  /// How long the user must wait before "Resend code" becomes tappable.
  final Duration resendCooldown;

  /// Passed to `FirebaseAuth.verifyPhoneNumber(timeout:)` — the window in
  /// which Android may auto-retrieve the SMS.
  final Duration smsAutoRetrievalTimeout;

  /// Number of OTP digits.
  final int otpLength;

  /// Send a verification email immediately after a successful sign-up.
  final bool sendVerificationEmailOnSignUp;

  /// Minimum password length enforced client-side. Firebase's own floor is 6.
  final int minPasswordLength;

  const DotAuthConfig({
    this.routes = const DotAuthRoutes(),
    this.defaultCountry = IsoCode.IN,
    this.resendCooldown = const Duration(seconds: 30),
    this.smsAutoRetrievalTimeout = const Duration(seconds: 60),
    this.otpLength = 6,
    this.sendVerificationEmailOnSignUp = true,
    this.minPasswordLength = 6,
  });
}

/// The active [DotAuthConfig]. Override in a [ProviderScope] to customise.
final dotAuthConfigProvider = Provider<DotAuthConfig>(
  (ref) => const DotAuthConfig(),
);

/// Convenience accessor for [DotAuthConfig.routes].
final dotAuthRoutesProvider = Provider<DotAuthRoutes>(
  (ref) => ref.watch(dotAuthConfigProvider).routes,
);
