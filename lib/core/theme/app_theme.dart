import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema modern PakaianKita: clean white, deep spruce green, modern neo-grotesque sans-serif.
class AppTheme {
  static const String uiFamily = 'PlusJakartaSans';
  static const String displayFamily = 'PlusJakartaSans';

  static ThemeData get lightTheme => _build();

  static ThemeData _build() {
    const scheme = ColorScheme.light(
      primary: AppColors.forest,
      onPrimary: Colors.white,
      primaryContainer: AppColors.sage,
      onPrimaryContainer: AppColors.forest,
      secondary: AppColors.claySoft,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.alertSurface,
      onSecondaryContainer: AppColors.clay,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.parchment,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
      error: AppColors.clay,
      onError: Colors.white,
      errorContainer: AppColors.alertSurface,
      onErrorContainer: AppColors.clay,
      shadow: Color(0x0F000000),
      scrim: Color(0x66111827),
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.paper,
      inversePrimary: AppColors.sage,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.paper,
      fontFamily: uiFamily,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: const TextStyle(
        fontFamily: displayFamily,
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: AppColors.ink,
      ),
      displayMedium: const TextStyle(
        fontFamily: displayFamily,
        fontSize: 30,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.ink,
      ),
      displaySmall: const TextStyle(
        fontFamily: displayFamily,
        fontSize: 26,
        height: 1.22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.ink,
      ),
      headlineLarge: const TextStyle(
        fontFamily: displayFamily,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.ink,
      ),
      headlineMedium: const TextStyle(
        fontFamily: displayFamily,
        fontSize: 21,
        height: 1.28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.ink,
      ),
      headlineSmall: const TextStyle(
        fontFamily: displayFamily,
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.ink,
      ),
      titleLarge: const TextStyle(
        fontFamily: uiFamily,
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.ink,
      ),
      titleMedium: const TextStyle(
        fontFamily: uiFamily,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: AppColors.ink,
      ),
      titleSmall: const TextStyle(
        fontFamily: uiFamily,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontFamily: uiFamily,
        fontSize: 16,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      ),
      bodyMedium: const TextStyle(
        fontFamily: uiFamily,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      ),
      bodySmall: const TextStyle(
        fontFamily: uiFamily,
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      ),
      labelLarge: const TextStyle(
        fontFamily: uiFamily,
        fontSize: 15,
        height: 1.33,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: AppColors.ink,
      ),
      labelMedium: const TextStyle(
        fontFamily: uiFamily,
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.forest,
      ),
      labelSmall: const TextStyle(
        fontFamily: uiFamily,
        fontSize: 11,
        height: 1.27,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.forest,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.clay),
        border: _inputBorder(AppColors.line, 1),
        enabledBorder: _inputBorder(AppColors.line, 1),
        focusedBorder: _inputBorder(AppColors.forest, 1.5),
        errorBorder: _inputBorder(AppColors.clay, 1),
        focusedErrorBorder: _inputBorder(AppColors.clay, 1.5),
        disabledBorder: _inputBorder(AppColors.line, 1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.muted,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          side: const BorderSide(color: AppColors.line, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          textStyle: textTheme.labelLarge?.copyWith(
            color: AppColors.forest,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.sage,
        disabledColor: AppColors.parchment,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.forest,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.line,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: const Color(0x1F111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: AppColors.sage,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.forest,
        linearTrackColor: AppColors.sage,
        circularTrackColor: AppColors.sage,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.forest;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: AppColors.muted, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.forest;
          }
          return AppColors.muted;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.forest;
          }
          return AppColors.line;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.muted,
        textColor: AppColors.ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.sage,
        height: 68,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? AppColors.forest : AppColors.muted,
            fontSize: 11,
            letterSpacing: 0.1,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppColors.forest : AppColors.muted,
          );
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
