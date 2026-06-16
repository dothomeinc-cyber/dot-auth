import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/auth_theme.dart';

/// Fixed-text T&C + Privacy Policy footer shown at the bottom of auth screens.
///
/// The display text is always:
/// "By continuing you are accepting the Terms & Conditions and Privacy Policy"
///
/// Both underlined phrases are tappable and navigate to the provided routes.
///
/// Example:
/// ```dart
/// TcFooter(
///   termsRoute: '/terms',
///   privacyRoute: '/privacy',
/// )
/// ```
class TcFooter extends StatelessWidget {
  /// Route path for the Terms & Conditions page. e.g. `'/terms'`
  final String termsRoute;

  /// Route path for the Privacy Policy page. e.g. `'/privacy'`
  final String privacyRoute;

  const TcFooter({
    super.key,
    required this.termsRoute,
    required this.privacyRoute,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = AuthTextStyles.caption;
    final linkStyle = baseStyle.copyWith(
      color: AuthColors.black80,
      decoration: TextDecoration.underline,
      decorationColor: AuthColors.black80,
    );

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: baseStyle,
          children: [
            const TextSpan(text: 'By continuing you are accepting the '),
            TextSpan(
              text: 'Terms & Conditions',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.go(termsRoute),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.go(privacyRoute),
            ),
          ],
        ),
      ),
    );
  }
}
