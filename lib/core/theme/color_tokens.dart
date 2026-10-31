import 'package:flutter/material.dart';

/// Design tokens resmi PakaianKita sesuai design.md & PRD v2.
///
/// Karakter: hangat, dapat dipercaya, praktis, gotong royong.
/// Tidak menggunakan gradient berlebihan atau shadow dekoratif berat (Taste-Skill guidance).
class AppColors {
  AppColors._();

  // Primary palette (Forest Green)
  static const Color primary = Color(0xFF145A46);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE4F2EA);
  static const Color onPrimaryContainer = Color(0xFF0A3327);

  // Neutral & Surfaces (Warm White Foundation)
  static const Color background = Color(0xFFFAFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3EE);
  static const Color outline = Color(0xFFD8E0DA);
  static const Color outlineVariant = Color(0xFFE8EDE9);

  // Inks & Typography
  static const Color textPrimary = Color(0xFF172D25);
  static const Color textSecondary = Color(0xFF4B6157);
  static const Color textTertiary = Color(0xFF7A8F85);

  // Semantic Emergency (Terracotta / Disaster Mode - FR-10)
  static const Color emergency = Color(0xFFB3261E);
  static const Color onEmergency = Color(0xFFFFFFFF);
  static const Color emergencyContainer = Color(0xFFFFF0EA);
  static const Color onEmergencyContainer = Color(0xFF681206);

  // Semantic Status
  static const Color warning = Color(0xFF765000);
  static const Color warningContainer = Color(0xFFFFF4CF);
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color success = Color(0xFF16603B);
  static const Color successContainer = Color(0xFFE4F7EC);
}
