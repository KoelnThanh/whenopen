import 'package:flutter/foundation.dart' show immutable;
import 'package:json_annotation/json_annotation.dart';

part 'app_einstellungen.g.dart';

/// Status des Erstnutzer-Tutorials.
///
/// - [offen]: noch nicht entschieden — Default, auch fuer Altdaten OHNE dieses
///   Feld (siehe `unknownEnumValue`). Das Tutorial darf beim ersten leeren
///   Start angeboten werden.
/// - [abgelehnt]: Nutzer hat „Nein" gewaehlt → dauerhaft nicht mehr fragen.
/// - [abgeschlossen]: Tutorial wurde durchlaufen/uebersprungen.
enum TutorialStatus { offen, abgelehnt, abgeschlossen }

/// App-Einstellungen (Schema 2.1).
///
/// Heute: optionale **Heimatadresse** + Suchradius fuer die „Orte in der
/// Naehe"-Suche sowie der **Tutorial-Status** der Erstnutzung. Die Adresse wird
/// EINMALIG per Nominatim zu Koordinaten aufgeloest und lokal gespeichert —
/// bewusst **ohne Standort-Berechtigung**, kein Tracking. Damit bleibt das
/// „alles bleibt lokal"-Versprechen erhalten.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class AppEinstellungen {
  const AppEinstellungen({
    this.heimatAdresse,
    this.heimatLat,
    this.heimatLon,
    this.umkreisMeter = AppEinstellungen.standardUmkreis,
    this.tutorialStatus = TutorialStatus.offen,
    this.spendenhinweisGezeigt = false,
  });

  /// Standard-Suchradius in Metern (1 km — bewusst eng fuer die Erstnutzung).
  static const standardUmkreis = 1000;

  /// Grenzen fuer den Umkreis-Regler (Meter).
  static const minUmkreis = 250;
  static const maxUmkreis = 5000;

  /// Angezeigter Adresstext (dient nur der Wiedererkennung).
  final String? heimatAdresse;

  /// Koordinaten der Heimatadresse (einmalig geocodet). `null` = nicht gesetzt.
  final double? heimatLat;
  final double? heimatLon;

  /// Suchradius in Metern (Standard [standardUmkreis]).
  final int umkreisMeter;

  /// Onboarding-/Tutorial-Status. `unknownEnumValue` faengt unbekannte/fehlende
  /// Werte aus aelteren Dateien ab → wirkt wie [TutorialStatus.offen], damit
  /// eine fehlende Angabe das Tutorial nie faelschlich unterdrueckt.
  @JsonKey(unknownEnumValue: TutorialStatus.offen)
  final TutorialStatus tutorialStatus;

  /// True, sobald der einmalige Unterstützen-/Feedback-Hinweis nach den ersten
  /// Einträgen gezeigt wurde — verhindert, dass er erneut aufpoppt. Fehlt das
  /// Feld in Altdaten, gilt `false` (Hinweis darf einmal erscheinen).
  final bool spendenhinweisGezeigt;

  /// True, wenn eine nutzbare Heimatposition hinterlegt ist.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hatHeimat => heimatLat != null && heimatLon != null;

  factory AppEinstellungen.fromJson(Map<String, dynamic> json) =>
      _$AppEinstellungenFromJson(json);

  Map<String, dynamic> toJson() => _$AppEinstellungenToJson(this);

  AppEinstellungen copyWith({
    String? heimatAdresse,
    double? heimatLat,
    double? heimatLon,
    bool heimatLoeschen = false,
    int? umkreisMeter,
    TutorialStatus? tutorialStatus,
    bool? spendenhinweisGezeigt,
  }) =>
      AppEinstellungen(
        heimatAdresse:
            heimatLoeschen ? null : (heimatAdresse ?? this.heimatAdresse),
        heimatLat: heimatLoeschen ? null : (heimatLat ?? this.heimatLat),
        heimatLon: heimatLoeschen ? null : (heimatLon ?? this.heimatLon),
        umkreisMeter: umkreisMeter ?? this.umkreisMeter,
        tutorialStatus: tutorialStatus ?? this.tutorialStatus,
        spendenhinweisGezeigt:
            spendenhinweisGezeigt ?? this.spendenhinweisGezeigt,
      );
}
