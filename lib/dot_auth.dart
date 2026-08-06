/// Firebase phone OTP and email/password authentication for Flutter, built on
/// Riverpod 3 and go_router.
///
/// ```dart
/// import 'package:dot_auth/dot_auth.dart';
/// ```
///
/// Screens: [AuthPhone], [OtpScreen], [AuthEmail].
/// State: [authStateProvider], [currentUserProvider], [phoneAuthProvider],
/// [emailAuthProvider].
/// Routing: [RouterNotifier], [AuthRouter].
/// Config: [DotAuthConfig], [dotAuthConfigProvider].
library;

export 'src/config/dot_auth_config.dart';
export 'src/models/models.dart';
export 'src/pages/email_screen.dart';
export 'src/pages/otp_screen.dart';
export 'src/pages/phone_screen.dart';
export 'src/providers/providers.dart';
export 'src/router/auth_router.dart';
export 'src/router/router_notifier.dart';
export 'src/theme/auth_theme.dart';
export 'src/utils/auth_error_mapper.dart';
export 'src/widgets/auth_wrapper.dart';
export 'src/widgets/error_line.dart';
export 'src/widgets/tc_footer.dart';
