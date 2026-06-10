import 'package:flutter/material.dart';

/// Farbwelt aus den Mockups (01-Konzept/mockups/whenopen-mockups.html, v0.2).
/// Dunkles Material-3-Theme mit Teal-Primaerfarbe.
abstract final class AppColors {
  static const bg = Color(0xFF0F1115);
  static const panel = Color(0xFF171A21);
  static const card = Color(0xFF1D212A);
  static const chip = Color(0xFF222732);
  static const line = Color(0xFF272B34);
  static const ink = Color(0xFFE8EAED);
  static const muted = Color(0xFF9AA0AA);
  static const primary = Color(0xFF2F6F6B);
  static const primaryInk = Color(0xFFCFEAE8);
  static const open = Color(0xFF28B765);
  static const closed = Color(0xFF7A818C);
  static const warn = Color(0xFFE0A32E);
  static const danger = Color(0xFFD9534F);

  /// Farb-Auswahl fuer Kategorien (Swatches aus dem Mockup).
  static const kategorieFarben = [
    Color(0xFF5B8DEF),
    Color(0xFF28B765),
    Color(0xFFE0843E),
    Color(0xFF9B6DD6),
    Color(0xFFE0566F),
  ];

  /// Fallback-Farbe fuer Kategorien ohne Farbe und fuer "Sonstige".
  static const kategorieFallback = Color(0xFF6B7280);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    surface: AppColors.bg,
    onSurface: AppColors.ink,
    surfaceContainerLow: AppColors.panel,
    surfaceContainer: AppColors.card,
    surfaceContainerHigh: AppColors.chip,
    outlineVariant: AppColors.line,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2A2F38),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      actionTextColor: const Color(0xFF7FE0B4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    cardTheme: CardThemeData(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1B1F27),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E232C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    timePickerTheme: const TimePickerThemeData(
      backgroundColor: Color(0xFF1E232C),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
  );
}
