import 'package:uuid/uuid.dart';

import '../../models/location.dart';
import '../../models/opening_day.dart';
import '../../models/wochentag.dart';

/// Flow-Zustand des Schnelleintrags (10 Schritte):
/// 0 = Name · 1–7 = Mo–So · 8 = Kategorie · 9 = Zusatzinfos.
class QuickEntryState {
  QuickEntryState();

  /// Bearbeiten-Modus: bestehende Location vorbefuellen (P05).
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
  }

  static const schritteGesamt = 10;
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

  int aktuellerSchritt = 0;

  bool get istBearbeiten => editId != null;
  bool get istLetzterSchritt => aktuellerSchritt == schritteGesamt - 1;

  /// Wochentag des aktuellen Schritts (nur fuer Schritte 1–7).
  Wochentag get aktuellerWochentag => Wochentag.values[aktuellerSchritt - 1];

  /// Vorschlag = Bloecke des letzten (in Wochenreihenfolge davorliegenden)
  /// Tags mit Oeffnungszeiten — nicht zwingend der unmittelbar vorherige Tag.
  List<TimeBlock>? vorschlagFuer(Wochentag tag) {
    for (var i = tag.index - 1; i >= 0; i--) {
      final bloecke = zeiten[Wochentag.values[i]]!;
      if (bloecke.isNotEmpty) return bloecke;
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
