import 'package:flutter/material.dart';

/// Palet PakaianKita diambil dari 20 layar handoff.
/// Nama lama tetap disediakan agar service/layar lama tidak pecah.
class AppColors {
  // Token utama.
  static const Color paper = Color(0xFFFAFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color parchment = Color(0xFFF2EDDF);
  static const Color sage = Color(0xFFE8EFE5);
  static const Color forest = Color(0xFF145A46);
  static const Color forestDeep = Color(0xFF0E4234);
  static const Color ink = Color(0xFF172D25);
  static const Color muted = Color(0xFF5C6B63);
  static const Color line = Color(0xFFDDE6D4);
  static const Color alertSurface = Color(0xFFFFF0EA);
  static const Color clay = Color(0xFFA33120);
  static const Color claySoft = Color(0xFFBA6052);
  static const Color sand = Color(0xFFB48B62);

  // Alias lama.
  static const Color primary = forest;
  static const Color primaryDark = forestDeep;
  static const Color primaryLight = sage;
  static const Color secondary = claySoft;
  static const Color secondaryLight = alertSurface;
  static const Color emergency = clay;
  static const Color emergencyLight = alertSurface;
  static const Color warning = Color(0xFF86601F);
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
  static const Color textMuted = Color(0xFF6B7A72);
}
