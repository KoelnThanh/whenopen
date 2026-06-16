import 'package:uuid/uuid.dart';

import '../../models/location.dart';
import '../../models/opening_day.dart';
import '../../models/wochentag.dart';

/// Flow-Zustand des Schnelleintrags (4 Schritte):
/// 0 = Name · 1 = Öffnungszeiten (Wochen-Editor) · 2 = Kategorie · 3 = Zusatzinfos.
///
/// Die Öffnungszeiten leben als eine Wochenliste statt sieben Einzelschritte
/// (UX-Redesign 2026-06: „Eine Woche, ein Editor"). Pro Tag gibt es drei
/// Zustände: geöffnet (Blöcke vorhanden), geschlossen (festgelegt, aber leer)
/// und „noch festlegen" (noch nicht in [festgelegt]).
class QuickEntryState {
  QuickEntryState();

  /// Bearbeiten-Modus: bestehende Location vorbefuellen (P05). Alle sieben Tage
  /// gelten dann als bewusst festgelegt.
  QuickEntryState.fromLocation(Location location)
      : editId = location.id,
        erstelltAm = location.erstelltAm,
        name = location.name,
        adresse = location.adresse ?? '',
        telefon = location.telefon ?? '',
        googleMapsLink = location.googleMapsLink ?? '',
        kategorieId = location.kategorie {
    for (final tag in location.oeffnungszeiten) {
      zeiten[tag.wochentag] = [...tag.zeiten];
    }
    festgelegt.addAll(Wochentag.values);
  }

  static const schritteGesamt = 4;
  static const _uuid = Uuid();

  String? editId;
  DateTime? erstelltAm;

  String name = '';
  String adresse = '';
  String telefon = '';
  String googleMapsLink = '';
  String? kategorieId;

  final Map<Wochentag, List<TimeBlock>> zeiten = {
    for (final w in Wochentag.values) w: <TimeBlock>[],
  };

  /// Tage, die der Nutzer bewusst festgelegt hat (geöffnet ODER geschlossen).
  /// Nicht enthaltene Tage sind „noch festlegen" und werden beim Speichern als
  /// geschlossen gewertet. Wird NICHT persistiert — reiner Eingabe-Zustand.
  final Set<Wochentag> festgelegt = {};

  int aktuellerSchritt = 0;

  bool get istBearbeiten => editId != null;
  bool get istLetzterSchritt => aktuellerSchritt == schritteGesamt - 1;

  /// Vorschlag = Bloecke des letzten (in Wochenreihenfolge davorliegenden)
  /// Tags mit Oeffnungszeiten — nicht zwingend der unmittelbar vorherige Tag.
  List<TimeBlock>? vorschlagFuer(Wochentag tag) {
    for (var i = tag.index - 1; i >= 0; i--) {
      final bloecke = zeiten[Wochentag.values[i]]!;
      if (bloecke.isNotEmpty) return bloecke;
    }
    return null;
  }

  /// Distinct Oeffnungszeit-Profile bereits **festgelegter** anderer Tage als
  /// Kopiervorlagen fuer [tag]. Haben mehrere Tage identische Bloecke, erscheint
  /// nur der erste (in Wochenreihenfolge Mo–So); der aktuelle Tag bleibt aussen
  /// vor. Bei Neuanlage sind das die schon ausgefuellten Tage davor, beim
  /// Bearbeiten alle uebrigen Tage. Grundlage fuer die „Wie ‹Tag›"-Chips.
  List<MapEntry<Wochentag, List<TimeBlock>>> uebernahmeVorschlaege(
      Wochentag tag) {
    final vorschlaege = <MapEntry<Wochentag, List<TimeBlock>>>[];
    final gesehen = <String>{};
    for (final w in Wochentag.values) {
      if (w == tag || !festgelegt.contains(w)) continue;
      final bloecke = zeiten[w]!;
      if (bloecke.isEmpty) continue; // nur geoeffnete Tage taugen als Vorlage
      final schluessel = bloecke.map((b) => b.toString()).join('|');
      if (gesehen.add(schluessel)) {
        vorschlaege.add(MapEntry(w, bloecke));
      }
    }
    return vorschlaege;
  }

  /// Erster noch nicht festgelegter Tag nach [tag] (Wochenreihenfolge), sonst
  /// null — Grundlage für die geführte Weiter-Navigation im Wochen-Editor.
  Wochentag? naechsterUnbestimmter(Wochentag tag) {
    for (var i = tag.index + 1; i < Wochentag.values.length; i++) {
      final kandidat = Wochentag.values[i];
      if (!festgelegt.contains(kandidat)) return kandidat;
    }
    return null;
  }

  Location toLocation() {
    final jetzt = DateTime.now().toUtc();
    return Location(
      id: editId ?? _uuid.v4(),
      name: name.trim(),
      oeffnungszeiten: [
        for (final w in Wochentag.values)
          OpeningDay(wochentag: w, zeiten: List.unmodifiable(zeiten[w]!)),
      ],
      adresse: adresse.trim().isEmpty ? null : adresse.trim(),
      telefon: telefon.trim().isEmpty ? null : telefon.trim(),
      googleMapsLink:
          googleMapsLink.trim().isEmpty ? null : googleMapsLink.trim(),
      kategorie: kategorieId,
      erstelltAm: erstelltAm ?? jetzt,
      geaendertAm: jetzt,
    );
  }
}
