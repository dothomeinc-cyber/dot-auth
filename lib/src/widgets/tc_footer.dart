import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/dot_auth_config.dart';
import '../theme/auth_theme.dart';

/// Terms & Conditions and Privacy Policy footer for the auth screens.
///
/// Routes come from [dotAuthRoutesProvider] unless overridden here. Both links
/// use `push`, so the user lands back on the auth screen when they come back.
class TcFooter extends ConsumerStatefulWidget {
  /// Overrides [DotAuthRoutes.terms].
  final String? termsRoute;

  /// Overrides [DotAuthRoutes.privacy].
  final String? privacyRoute;

  const TcFooter({super.key, this.termsRoute, this.privacyRoute});

  @override
  ConsumerState<TcFooter> createState() => _TcFooterState();
}

class _TcFooterState extends ConsumerState<TcFooter> {
  // Recognizers hold a callback each and must be disposed. Building them
  // inside build() leaks one pair per rebuild.
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _openTerms;
    _privacyTap = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _openTerms() {
    final routes = ref.read(dotAuthRoutesProvider);
    context.push(widget.termsRoute ?? routes.terms);
  }

  void _openPrivacy() {
    final routes = ref.read(dotAuthRoutesProvider);
    context.push(widget.privacyRoute ?? routes.privacy);
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = AuthTextStyles.caption.copyWith(
      color: AuthColors.black80,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AuthColors.black80,
    );

    return Center(
      child: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          style: AuthTextStyles.caption,
          children: [
            const TextSpan(text: 'By continuing you accept the '),
            TextSpan(
              text: 'Terms & Conditions',
              style: linkStyle,
              recognizer: _termsTap,
              semanticsLabel: 'Open Terms and Conditions',
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: linkStyle,
              recognizer: _privacyTap,
              semanticsLabel: 'Open Privacy Policy',
            ),
          ],
        ),
      ),
    );
  }
}
