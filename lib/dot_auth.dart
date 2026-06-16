/// dot_auth — Firebase phone OTP + email/password authentication for Flutter.
///
/// Quick start:
/// ```dart
/// import 'package:dot_auth/dot_auth.dart';
/// ```
///
/// Key exports:
/// - [AuthPhone] — phone number entry screen
/// - [OtpScreen] — OTP verification screen
/// - [AuthEmail] — email sign in / sign up / reset screen
/// - [authStateProvider] — main auth state
/// - [currentUserProvider] — signed-in [UserModel]
/// - [RouterNotifier] — bridges auth state to go_router
/// - [AuthRouter] — optional convenience router factory
/// - [authTheme] — preconfigured [ThemeData]
/// - [TcFooter] — T&C + Privacy Policy footer widget
library;

export 'src/models/models.dart';
export 'src/providers/auth_provider.dart';
export 'src/router/auth_router.dart';
export 'src/router/router_notifier.dart';
export 'src/widgets/auth_wrapper.dart';
export 'src/widgets/tc_footer.dart';
export 'src/pages/phone_screen.dart';
export 'src/pages/otp_screen.dart';
export 'src/pages/email_screen.dart';
export 'src/theme/auth_theme.dart';
