import 'package:flutter/material.dart';

import 'pk_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _create(
    brightness: Brightness.light,
    tokens: PkTokens.light,
    primary: PkPalette.deepGreen,
    onPrimary: Colors.white,
  );

  static ThemeData dark() => _create(
    brightness: Brightness.dark,
    tokens: PkTokens.dark,
    primary: PkPalette.teal,
    onPrimary: PkPalette.darkBackground,
  );

  static ThemeData _create({
    required Brightness brightness,
    required PkTokens tokens,
    required Color primary,
    required Color onPrimary,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: tokens.accent,
      onSecondary: tokens.onAccent,
      error: tokens.terracotta,
      onError: Colors.white,
      surface: tokens.surface,
      onSurface: tokens.onSurface,
    );
    final baseTextTheme = ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: tokens.fontFamily,
      bodyColor: tokens.onSurface,
      displayColor: tokens.onSurface,
    );
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontFamily: tokens.fontFamily,
        fontSize: tokens.displayFontSize,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: tokens.fontFamily,
        fontSize: tokens.headlineFontSize,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: tokens.fontFamily,
        fontSize: tokens.titleFontSize,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontFamily: tokens.fontFamily,
        fontSize: tokens.bodyFontSize,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontFamily: tokens.fontFamily,
        fontSize: tokens.labelFontSize,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.background,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
      iconTheme: IconThemeData(color: tokens.onSurface),
      dividerColor: tokens.border,
      splashFactory: InkSparkle.splashFactory,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusControl),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusControl),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusControl),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusControl),
          borderSide: BorderSide(color: tokens.accent, width: 1.5),
        ),
      ),
    );
  }
}
