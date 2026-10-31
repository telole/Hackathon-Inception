import 'package:flutter/material.dart';

/// Palet warna modern editorial PakaianKita:
/// Hijau Pinus / Spruce Green (#1E5E4E), Deep Charcoal (#111827), Neutral Slate (#4B5563),
/// Pure Clean White (#FFFFFF), Modern Mint (#E6F4EA).
class AppColors {
  // Token utama
  static const Color paper = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color parchment = Color(0xFFF3F4F6); // Neutral subtle card/tag fill
  static const Color sage = Color(0xFFE6F4EA);      // Fresh modern sage mint
  static const Color forest = Color(0xFF1E5E4E);    // Deep pine / spruce green
  static const Color forestDeep = Color(0xFF144538);
  static const Color ink = Color(0xFF111827);       // Deep charcoal / modern neo-grotesque black
  static const Color muted = Color(0xFF4B5563);     // Neutral slate gray, super legible
  static const Color line = Color(0xFFE5E7EB);      // Subtle modern hairline border
  static const Color alertSurface = Color(0xFFFEF2F2);
  static const Color clay = Color(0xFFDC2626);      // Clean danger / alert
  static const Color claySoft = Color(0xFFEF4444);
  static const Color sand = Color(0xFFD97706);

  // Alias lama agar backward-compatible
  static const Color primary = forest;
  static const Color primaryDark = forestDeep;
  static const Color primaryLight = sage;
  static const Color secondary = claySoft;
  static const Color secondaryLight = alertSurface;
  static const Color emergency = clay;
  static const Color emergencyLight = alertSurface;
  static const Color warning = Color(0xFFB45309);
  static const Color warningLight = parchment;
  static const Color success = forest;
  static const Color successLight = sage;
  static const Color info = muted;
  static const Color infoLight = sage;
  static const Color background = paper;
  static const Color border = line;
  static const Color borderFocused = forest;
  static const Color textPrimary = ink;
  static const Color textSecondary = muted;
  static const Color textMuted = Color(0xFF6B7280);
}
