import 'package:flutter/material.dart';

/// Farbwelt v0.3 (01-Konzept/mockups/whenopen-mockups.html, Sektion „v0.3").
/// Neue Markenfarbe **Indigo**; App unterstuetzt Hell + Dunkel (folgt System).
///
/// [AppColors] = markenfeste, in beiden Themes gleiche Farben (Primaer,
/// Status, Kategorie-Swatches). Die *neutralen* Flaechen-/Textfarben, die
/// zwischen Hell und Dunkel kippen, liegen in [AppPalette] (ThemeExtension)
/// und werden ueber `context.col` gelesen.
abstract final class AppColors {
  // Markenfarbe (Indigo) — gleich in Hell + Dunkel.
  static const primary = Color(0xFF6366F1);
  static const primaryDeep = Color(0xFF4F46E5);
  static const primaryInk = Color(0xFFA5B4FC); // heller Indigo (Akzenttext dunkel)

  // Status — gleich in beiden Themes.
  static const open = Color(0xFF34D399);
  static const closed = Color(0xFF8A929E);
  static const warn = Color(0xFFE0A32E);
  static const danger = Color(0xFFE5534F);

  /// Farb-Auswahl fuer Kategorien (Swatches aus dem Mockup).
  static const kategorieFarben = [
    Color(0xFF6366F1),
    Color(0xFF34D399),
    Color(0xFFF59E0B),
    Color(0xFF9B6DD6),
    Color(0xFFE0566F),
  ];

  /// Fallback-Farbe fuer Kategorien ohne Farbe und fuer "Sonstige".
  static const kategorieFallback = Color(0xFF6B7280);

  // ── Kompatibilitaet: Dunkel-Werte als const (Stellen, die noch nicht auf
  //    `context.col` migriert sind, kompilieren weiter und sehen dunkel aus).
  static const bg = Color(0xFF0E1116);
  static const panel = Color(0xFF161A22);
  static const card = Color(0xFF1F242E);
  static const chip = Color(0xFF242B39);
  static const line = Color(0xFF272D38);
  static const ink = Color(0xFFECEFF3);
  static const muted = Color(0xFF98A0AD);
}

/// Neutrale, theme-abhaengige Farben (kippen zwischen Hell und Dunkel).
/// Zugriff in Widgets ueber `context.col`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.card,
    required this.chip,
    required this.line,
    required this.ink,
    required this.muted,
    required this.primaryInk,
    required this.open,
    required this.closed,
  });

  final Color bg;
  final Color surface;
  final Color card;
  final Color chip;
  final Color line;
  final Color ink;
  final Color muted;
  final Color primaryInk;
  final Color open;
  final Color closed;

  static const dark = AppPalette(
    bg: Color(0xFF0E1116),
    surface: Color(0xFF161A22),
    card: Color(0xFF1F242E),
    chip: Color(0xFF242B39),
    line: Color(0xFF272D38),
    ink: Color(0xFFECEFF3),
    muted: Color(0xFF98A0AD),
    primaryInk: Color(0xFFA5B4FC),
    open: Color(0xFF34D399),
    closed: Color(0xFF8A929E),
  );

  static const light = AppPalette(
    bg: Color(0xFFF4F6FA),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    chip: Color(0xFFEEF1F6),
    line: Color(0xFFE7EBF1),
    ink: Color(0xFF19212E),
    muted: Color(0xFF5C6573),
    primaryInk: Color(0xFF4F46E5),
    open: Color(0xFF16A34A),
    closed: Color(0xFF6B7280),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? card,
    Color? chip,
    Color? line,
    Color? ink,
    Color? muted,
    Color? primaryInk,
    Color? open,
    Color? closed,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      chip: chip ?? this.chip,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      primaryInk: primaryInk ?? this.primaryInk,
      open: open ?? this.open,
      closed: closed ?? this.closed,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      primaryInk: Color.lerp(primaryInk, other.primaryInk, t)!,
      open: Color.lerp(open, other.open, t)!,
      closed: Color.lerp(closed, other.closed, t)!,
    );
  }
}

/// Bequemer Zugriff auf die theme-abhaengige Palette: `context.col.muted`.
extension AppPaletteX on BuildContext {
  AppPalette get col => Theme.of(this).extension<AppPalette>()!;
}

/// Hell + Dunkel werden parallel an `MaterialApp` gegeben; `themeMode`
/// (gesteuert über [ThemeModus] in den Einstellungen) entscheidet zur Laufzeit.
ThemeData buildDarkTheme() => _baseTheme(Brightness.dark, AppPalette.dark);

ThemeData buildLightTheme() => _baseTheme(Brightness.light, AppPalette.light);

ThemeData _baseTheme(Brightness brightness, AppPalette p) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    surface: p.bg,
    onSurface: p.ink,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.card,
    surfaceContainerHigh: p.chip,
    outlineVariant: p.line,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [p],
    scaffoldBackgroundColor: p.bg,
    // Flache, ruhige AppBar in Flaechenfarbe statt farbigem Balken.
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      // Dunkle SnackBar in beiden Modi — gängiges Material-Muster, gut lesbar.
      backgroundColor: const Color(0xFF2A2F38),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      // SnackBar ist in beiden Modi dunkel → heller Indigo-Akzent passt fest.
      actionTextColor: AppPalette.dark.primaryInk,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1),
    cardTheme: CardThemeData(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: p.line),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    timePickerTheme: TimePickerThemeData(backgroundColor: p.surface),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: TextStyle(color: p.muted),
    ),
  );
}
