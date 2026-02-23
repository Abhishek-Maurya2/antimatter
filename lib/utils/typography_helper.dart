import 'package:flutter/material.dart';

class TypographyHelper {
  /// Returns a Material 3 compliant TextTheme using local custom fonts.
  /// M3 defines 5 type families: Display, Headline, Title, Body, Label.
  static TextTheme getTextTheme(BuildContext context) {
    // We use a base text theme to provide the correct default colors for the current brightness
    final baseTheme = Theme.of(context).textTheme;

    // Use NotoSans for Display/Headline/Title and RobotoFlex for Body/Label
    const String displayFont = 'NotoSans';
    const String bodyFont = 'RobotoFlex';

    return baseTheme.copyWith(
      displayLarge: const TextStyle(
        fontFamily: displayFont,
        fontSize: 57,
        fontWeight: FontWeight.w500, // available weights: 500, 600, 700
        height: 64 / 57,
        letterSpacing: -0.25,
      ),
      displayMedium: const TextStyle(
        fontFamily: displayFont,
        fontSize: 45,
        fontWeight: FontWeight.w500,
        height: 52 / 45,
        letterSpacing: 0,
      ),
      displaySmall: const TextStyle(
        fontFamily: displayFont,
        fontSize: 36,
        fontWeight: FontWeight.w500,
        height: 44 / 36,
        letterSpacing: 0,
      ),

      headlineLarge: const TextStyle(
        fontFamily: displayFont,
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 40 / 32,
        letterSpacing: 0,
      ),
      headlineMedium: const TextStyle(
        fontFamily: displayFont,
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 36 / 28,
        letterSpacing: 0,
      ),
      headlineSmall: const TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 32 / 24,
        letterSpacing: 0,
      ),

      titleLarge: const TextStyle(
        fontFamily: displayFont,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 28 / 22,
        letterSpacing: 0,
      ),
      titleMedium: const TextStyle(
        fontFamily: displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        letterSpacing: 0.15,
      ),
      titleSmall: const TextStyle(
        fontFamily: displayFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.1,
      ),

      bodyLarge: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        letterSpacing: 0.5,
      ),
      bodyMedium: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        letterSpacing: 0.25,
      ),
      bodySmall: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        letterSpacing: 0.4,
      ),

      labelLarge: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        letterSpacing: 0.1,
      ),
      labelMedium: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.5,
      ),
      labelSmall: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 16 / 11,
        letterSpacing: 0.5,
      ),
    );
  }
}
