import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette.
class AuthColors {
  AuthColors._();

  static const white = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF5F5F5);
  static const black = Color(0xFF0A0A0A);
  static const black80 = Color(0xCC0A0A0A);
  static const black50 = Color(0x800A0A0A);
  static const black15 = Color(0x260A0A0A);

  /// Brand yellow. Use it as a **background** only.
  ///
  /// Yellow text on white measures about 1.3:1 against WCAG's 4.5:1 floor —
  /// unreadable outdoors, which is where a lot of this app gets used. Black on
  /// yellow is 15:1, so filled buttons are fine.
  static const yellow = Color(0xFFFFE000);

  /// Text links. Underlined black, not yellow — see [yellow].
  static const link = black;

  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
}

/// Font source for [AuthTextStyles].
///
/// `google_fonts` downloads Urbanist on first launch, which fails on a bad
/// connection. To bundle the font instead, add it to your app's pubspec and
/// point this at it before `runApp`:
///
/// ```dart
/// DotAuthTypography.fontFamily = 'Urbanist';
/// ```
class DotAuthTypography {
  DotAuthTypography._();

  /// A bundled family name, or `null` to fetch Urbanist via `google_fonts`.
  static String? fontFamily;

  /// Applies the configured font to [style].
  static TextStyle apply(TextStyle style) {
    if (fontFamily != null) return style.copyWith(fontFamily: fontFamily);
    return GoogleFonts.urbanist(textStyle: style);
  }
}

/// Type scale. Requires `ScreenUtilInit(designSize: Size(375, 812))`.
class AuthTextStyles {
  AuthTextStyles._();

  static TextStyle _s({
    required double size,
    required FontWeight weight,
    required Color color,
  }) =>
      DotAuthTypography.apply(
        TextStyle(fontSize: size, fontWeight: weight, color: color),
      );

  static TextStyle get headlineM =>
      _s(size: 26.sp, weight: FontWeight.w700, color: AuthColors.black);

  static TextStyle get headlineS =>
      _s(size: 22.sp, weight: FontWeight.w600, color: AuthColors.black);

  static TextStyle get titleM =>
      _s(size: 16.sp, weight: FontWeight.w600, color: AuthColors.black);

  static TextStyle get bodyL =>
      _s(size: 16.sp, weight: FontWeight.w400, color: AuthColors.black80);

  static TextStyle get bodyM =>
      _s(size: 14.sp, weight: FontWeight.w400, color: AuthColors.black80);

  static TextStyle get labelM =>
      _s(size: 12.sp, weight: FontWeight.w700, color: AuthColors.black);

  static TextStyle get ctaLabel =>
      _s(size: 15.sp, weight: FontWeight.w800, color: AuthColors.black);

  static TextStyle get caption =>
      _s(size: 12.sp, weight: FontWeight.w500, color: AuthColors.black50);

  /// Inline link — underlined so it reads as tappable without relying on hue.
  static TextStyle get link => _s(
        size: 14.sp,
        weight: FontWeight.w700,
        color: AuthColors.link,
      ).copyWith(
        decoration: TextDecoration.underline,
        decorationColor: AuthColors.link,
      );

  static TextStyle get errorText =>
      _s(size: 12.sp, weight: FontWeight.w500, color: AuthColors.error);
}

/// [ThemeData] preconfigured with the dot_auth design system.
///
/// Apply with `MaterialApp(theme: authTheme())`.
ThemeData authTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AuthColors.white,
    colorScheme: const ColorScheme.light(
      primary: AuthColors.yellow,
      onPrimary: AuthColors.black,
      surface: AuthColors.white,
      onSurface: AuthColors.black,
      error: AuthColors.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AuthColors.white,
      foregroundColor: AuthColors.black,
      elevation: 0,
      titleTextStyle: AuthTextStyles.headlineS,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AuthColors.yellow,
        foregroundColor: AuthColors.black,
        disabledBackgroundColor: AuthColors.surfaceLight,
        disabledForegroundColor: AuthColors.black50,
        elevation: 0,
        minimumSize: Size(0, 48.h),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        textStyle: AuthTextStyles.ctaLabel,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AuthColors.link),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AuthColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AuthColors.black15),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AuthColors.black, width: 1.5.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AuthColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AuthColors.error, width: 1.5.w),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      labelStyle: AuthTextStyles.bodyM,
      errorStyle: AuthTextStyles.errorText,
    ),
  );
}
