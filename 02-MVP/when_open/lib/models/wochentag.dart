import 'package:json_annotation/json_annotation.dart';

/// Wochentage Mo–So. JSON-Werte entsprechen dem Schema 2.0 ("mo".."so").
/// Dart-Namen sind ausgeschrieben, weil `do` ein reserviertes Wort ist.
enum Wochentag {
  @JsonValue('mo')
  montag,
  @JsonValue('di')
  dienstag,
  @JsonValue('mi')
  mittwoch,
  @JsonValue('do')
  donnerstag,
  @JsonValue('fr')
  freitag,
  @JsonValue('sa')
  samstag,
  @JsonValue('so')
  sonntag;

  /// Dart: DateTime.weekday liefert 1 (Mo) bis 7 (So).
  static Wochentag fromDateTime(DateTime dt) => values[dt.weekday - 1];

  /// JSON-Kuerzel ("mo".."so") fuer manuelle Serialisierung.
  String get kuerzel => const ['mo', 'di', 'mi', 'do', 'fr', 'sa', 'so'][index];

  static Wochentag fromKuerzel(String kuerzel) =>
      values.firstWhere((w) => w.kuerzel == kuerzel,
          orElse: () => throw FormatException('Unbekannter Wochentag: $kuerzel'));

  /// Der Tag, der [tage] nach diesem kommt (zyklisch ueber die Wochengrenze).
  Wochentag plus(int tage) => values[(index + tage) % 7];
}
