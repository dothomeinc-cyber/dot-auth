import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/auth_theme.dart';

/// Inline failure message used across the auth screens.
///
/// Marked as a live region so screen readers announce it when it appears —
/// otherwise a blind user gets no feedback that their submission failed.
class AuthErrorLine extends StatelessWidget {
  /// What went wrong, in the interface's voice.
  final String message;

  /// Centres the row. Defaults to left-aligned.
  final bool centered;

  const AuthErrorLine({
    super.key,
    required this.message,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment:
            centered ? MainAxisAlignment.center : MainAxisAlignment.start,
        mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child:
                Icon(Icons.error_outline, size: 16.sp, color: AuthColors.error),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              message,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: AuthTextStyles.bodyM.copyWith(color: AuthColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
