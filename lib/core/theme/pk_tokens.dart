import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

abstract final class PkPalette {
  static const teal = Color(0xFF1D9E75);
  static const deepGreen = Color(0xFF085041);
  static const forest = Color(0xFF0F6E56);
  static const cream = Color(0xFFF5F1E8);
  static const charcoal = Color(0xFF2C2C2A);
  static const orange = Color(0xFFEF9F27);
  static const terracotta = Color(0xFFD85A30);
  static const darkBackground = Color(0xFF0E1A17);
  static const darkSurface = Color(0xFF14261F);
}

@immutable
class PkTokens extends ThemeExtension<PkTokens> {
  const PkTokens({
    required this.accent,
    required this.accentStrong,
    required this.background,
    required this.border,
    required this.cardShadow,
    required this.deepGreen,
    required this.displayFontSize,
    required this.fontFamily,
    required this.headlineFontSize,
    required this.mutedText,
    required this.onAccent,
    required this.onSurface,
    required this.orange,
    required this.stitch,
    required this.surface,
    required this.bodyFontSize,
    required this.labelFontSize,
    required this.titleFontSize,
    required this.terracotta,
    required this.radiusCard,
    required this.radiusControl,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
  });

  final Color accent;
  final Color accentStrong;
  final Color background;
  final Color border;
  final BoxShadow cardShadow;
  final Color deepGreen;
  final double displayFontSize;
  final String fontFamily;
  final double headlineFontSize;
  final Color mutedText;
  final Color onAccent;
  final Color onSurface;
  final Color orange;
  final Color stitch;
  final Color surface;
  final double bodyFontSize;
  final double labelFontSize;
  final double titleFontSize;
  final Color terracotta;
  final double radiusCard;
  final double radiusControl;
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;

  static const light = PkTokens(
    accent: PkPalette.teal,
    accentStrong: PkPalette.deepGreen,
    background: PkPalette.cream,
    border: Color(0xFFE2DDD2),
    cardShadow: BoxShadow(
      color: Color(0x120F3D30),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
    deepGreen: PkPalette.deepGreen,
    displayFontSize: 40,
    fontFamily: 'Poppins',
    headlineFontSize: 32,
    mutedText: Color(0xFF64645D),
    onAccent: Colors.white,
    onSurface: PkPalette.charcoal,
    orange: PkPalette.orange,
    stitch: PkPalette.teal,
    surface: Color(0xFFFFFEFB),
    bodyFontSize: 14,
    labelFontSize: 12,
    titleFontSize: 18,
    terracotta: PkPalette.terracotta,
    radiusCard: 28,
    radiusControl: 18,
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 16,
    spaceLg: 24,
    spaceXl: 32,
  );

  static const dark = PkTokens(
    accent: Color(0xFF4CC49A),
    accentStrong: Color(0xFF4CC49A),
    background: PkPalette.darkBackground,
    border: Color(0xFF284138),
    cardShadow: BoxShadow(
      color: Color(0x44000000),
      blurRadius: 26,
      offset: Offset(0, 12),
    ),
    deepGreen: PkPalette.deepGreen,
    displayFontSize: 40,
    fontFamily: 'Poppins',
    headlineFontSize: 32,
    mutedText: Color(0xFFB4C3BC),
    onAccent: PkPalette.darkBackground,
    onSurface: PkPalette.cream,
    orange: PkPalette.orange,
    stitch: Color(0xFF4CC49A),
    surface: PkPalette.darkSurface,
    bodyFontSize: 14,
    labelFontSize: 12,
    titleFontSize: 18,
    terracotta: PkPalette.terracotta,
    radiusCard: 28,
    radiusControl: 18,
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 16,
    spaceLg: 24,
    spaceXl: 32,
  );

  @override
  PkTokens copyWith({
    Color? accent,
    Color? accentStrong,
    Color? background,
    Color? border,
    BoxShadow? cardShadow,
    Color? deepGreen,
    double? displayFontSize,
    String? fontFamily,
    double? headlineFontSize,
    Color? mutedText,
    Color? onAccent,
    Color? onSurface,
    Color? orange,
    Color? stitch,
    Color? surface,
    double? bodyFontSize,
    double? labelFontSize,
    double? titleFontSize,
    Color? terracotta,
    double? radiusCard,
    double? radiusControl,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
  }) {
    return PkTokens(
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      background: background ?? this.background,
      border: border ?? this.border,
      cardShadow: cardShadow ?? this.cardShadow,
      deepGreen: deepGreen ?? this.deepGreen,
      displayFontSize: displayFontSize ?? this.displayFontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      headlineFontSize: headlineFontSize ?? this.headlineFontSize,
      mutedText: mutedText ?? this.mutedText,
      onAccent: onAccent ?? this.onAccent,
      onSurface: onSurface ?? this.onSurface,
      orange: orange ?? this.orange,
      stitch: stitch ?? this.stitch,
      surface: surface ?? this.surface,
      bodyFontSize: bodyFontSize ?? this.bodyFontSize,
      labelFontSize: labelFontSize ?? this.labelFontSize,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      terracotta: terracotta ?? this.terracotta,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusControl: radiusControl ?? this.radiusControl,
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
    );
  }

  @override
  PkTokens lerp(ThemeExtension<PkTokens>? other, double t) {
    if (other is! PkTokens) return this;

    return PkTokens(
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      cardShadow: BoxShadow.lerp(cardShadow, other.cardShadow, t)!,
      deepGreen: Color.lerp(deepGreen, other.deepGreen, t)!,
      displayFontSize: lerpDouble(displayFontSize, other.displayFontSize, t)!,
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      headlineFontSize: lerpDouble(
        headlineFontSize,
        other.headlineFontSize,
        t,
      )!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      stitch: Color.lerp(stitch, other.stitch, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      bodyFontSize: lerpDouble(bodyFontSize, other.bodyFontSize, t)!,
      labelFontSize: lerpDouble(labelFontSize, other.labelFontSize, t)!,
      titleFontSize: lerpDouble(titleFontSize, other.titleFontSize, t)!,
      terracotta: Color.lerp(terracotta, other.terracotta, t)!,
      radiusCard: lerpDouble(radiusCard, other.radiusCard, t)!,
      radiusControl: lerpDouble(radiusControl, other.radiusControl, t)!,
      spaceXs: lerpDouble(spaceXs, other.spaceXs, t)!,
      spaceSm: lerpDouble(spaceSm, other.spaceSm, t)!,
      spaceMd: lerpDouble(spaceMd, other.spaceMd, t)!,
      spaceLg: lerpDouble(spaceLg, other.spaceLg, t)!,
      spaceXl: lerpDouble(spaceXl, other.spaceXl, t)!,
    );
  }
}
