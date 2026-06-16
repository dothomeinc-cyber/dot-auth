import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand colour palette used across all dot_auth screens.
class AuthColors {
  AuthColors._();

  static const white = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF5F5F5);
  static const black = Color(0xFF0A0A0A);
  static const black80 = Color(0xCC0A0A0A);
  static const black50 = Color(0x800A0A0A);
  static const black15 = Color(0x260A0A0A);

  /// Primary yellow — buttons, active links, accents.
  static const yellow = Color(0xFFFFE000);

  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
}

/// Text styles using Google Fonts Urbanist with flutter_screenutil scaling.
///
/// Host app must initialise [ScreenUtilInit] with
/// `designSize: const Size(375, 812)`.
class AuthTextStyles {
  AuthTextStyles._();

  static TextStyle get headlineM => GoogleFonts.urbanist(
        fontSize: 26.sp,
        fontWeight: FontWeight.w700,
        color: AuthColors.black,
      );

  static TextStyle get headlineS => GoogleFonts.urbanist(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: AuthColors.black,
      );

  static TextStyle get titleM => GoogleFonts.urbanist(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AuthColors.black,
      );

  static TextStyle get bodyL => GoogleFonts.urbanist(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AuthColors.black80,
      );

  static TextStyle get bodyM => GoogleFonts.urbanist(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AuthColors.black80,
      );

  static TextStyle get labelM => GoogleFonts.urbanist(
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        color: AuthColors.black,
      );

  static TextStyle get ctaLabel => GoogleFonts.urbanist(
        fontSize: 15.sp,
        fontWeight: FontWeight.w800,
        color: AuthColors.black,
      );

  static TextStyle get caption => GoogleFonts.urbanist(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AuthColors.black50,
      );
}

/// Returns a [ThemeData] preconfigured with the dot_auth design system.
///
/// Apply via `MaterialApp(theme: authTheme())`.
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
      titleTextStyle: GoogleFonts.urbanist(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AuthColors.black,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AuthColors.yellow,
        foregroundColor: AuthColors.black,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        textStyle: AuthTextStyles.ctaLabel,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AuthColors.surfaceLight,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AuthColors.black15),
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
      errorStyle: GoogleFonts.urbanist(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: AuthColors.error,
      ),
    ),
  );
}
