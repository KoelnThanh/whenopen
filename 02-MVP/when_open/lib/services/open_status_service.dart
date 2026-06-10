import 'package:flutter/material.dart' show TimeOfDay;

import '../l10n/app_localizations.dart';
import '../models/location.dart';
import '../models/open_status.dart';
import '../models/opening_day.dart';
import '../models/wochentag.dart';

/// Kernlogik der App: "Jetzt geoeffnet?" (E9-Blocklogik) und das
/// Scheduling-Fundament fuer E16 (naechsteAenderung).
///
/// Zustandslos und ohne `DateTime.now()` — die Zeit kommt immer als
/// Parameter, damit jeder Zeitpunkt testbar ist. Wird auch vom
/// Widget-Hintergrundprozess genutzt (kein Riverpod-State hier).
abstract final class OpenStatusService {
  /// Ist [location] zum Zeitpunkt [now] geoeffnet?
  /// Geoeffnet ⇔ now liegt in irgendeinem Block (von <= t < bis) des Tages.
  static OpenStatus isOpenNow(Location location, DateTime now) {
    final heute = Wochentag.fromDateTime(now);
    final tag = location.tagFuer(heute);
    final jetztMinuten = now.hour * 60 + now.minute;

    for (final block in tag.zeiten) {
      if (jetztMinuten >= block.von.inMinuten &&
          jetztMinuten < block.bis.inMinuten) {
        return OpenStatus.offen(schliesstUm: block.bis);
      }
    }

    // Geschlossen. Gibt es heute noch einen spaeteren Block (Pause)?
    TimeBlock? naechsterHeute;
    for (final block in tag.zeiten) {
      if (block.von.inMinuten > jetztMinuten &&
          (naechsterHeute == null ||
              block.von.inMinuten < naechsterHeute.von.inMinuten)) {
        naechsterHeute = block;
      }
    }
    if (naechsterHeute != null) {
      return OpenStatus.geschlossen(
        naechsteOeffnung: NextOpening(
          wochentag: heute,
          von: naechsterHeute.von,
          tageVoraus: 0,
        ),
      );
    }

    return OpenStatus.geschlossen(
        naechsteOeffnung: findNextOpening(location, now));
  }

  /// Naechster geoeffneter Tag in den kommenden 7 Tagen (heute+1 … heute+7).
  /// Der Fall "heute, aber spaeterer Block" wird bereits in [isOpenNow]
  /// behandelt. `null` = Ort ist an keinem Tag geoeffnet.
  static NextOpening? findNextOpening(Location location, DateTime now) {
    final heute = Wochentag.fromDateTime(now);
    for (var i = 1; i <= 7; i++) {
      final tag = location.tagFuer(heute.plus(i));
      if (tag.geoeffnet) {
        final ersterBlock = tag.zeiten.reduce(
            (a, b) => a.von.inMinuten <= b.von.inMinuten ? a : b);
        return NextOpening(
          wochentag: tag.wochentag,
          von: ersterBlock.von,
          tageVoraus: i,
        );
      }
    }
    return null;
  }

  /// E16: Zeitpunkt der naechsten Statusaenderung — die kleinste echt
  /// zukuenftige Block-Grenze (von/bis) des heutigen Tages ueber alle
  /// Eintraege, sonst die naechste Mitternacht (Wochentagswechsel).
  /// App-Timer und Widget-Alarm wachen genau dann auf.
  static DateTime naechsteAenderung(List<Location> locations, DateTime now) {
    final heute = Wochentag.fromDateTime(now);
    final jetztMinuten = now.hour * 60 + now.minute;

    int? naechsteMinute;
    for (final location in locations) {
      for (final block in location.tagFuer(heute).zeiten) {
        for (final grenze in [block.von.inMinuten, block.bis.inMinuten]) {
          if (grenze > jetztMinuten &&
              (naechsteMinute == null || grenze < naechsteMinute)) {
            naechsteMinute = grenze;
          }
        }
      }
    }

    if (naechsteMinute != null) {
      return DateTime(
          now.year, now.month, now.day, naechsteMinute ~/ 60, naechsteMinute % 60);
    }
    // Keine Grenze mehr heute → Mitternacht (Datums-/Wochentagswechsel).
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// Bereitet die Widget-Daten auf: offen oben, geschlossen unten,
  /// alphabetisch sortiert, mit fertigem Statustext (alle Strings via ARB).
  static WidgetData buildWidgetData(
      List<Location> locations, DateTime now, AppLocalizations l10n) {
    final geoeffnet = <WidgetEntry>[];
    final geschlossen = <WidgetEntry>[];

    for (final location in locations) {
      final status = isOpenNow(location, now);
      final entry = WidgetEntry(
        id: location.id,
        name: location.name,
        statusText: statusText(status, l10n),
        offen: status.offen,
        kategorieId: location.kategorie,
      );
      (status.offen ? geoeffnet : geschlossen).add(entry);
    }

    int nachName(WidgetEntry a, WidgetEntry b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    geoeffnet.sort(nachName);
    geschlossen.sort(nachName);

    return WidgetData(geoeffnet: geoeffnet, geschlossen: geschlossen);
  }

  /// Kurzer Statustext fuer Liste und Widget.
  static String statusText(OpenStatus status, AppLocalizations l10n) {
    if (status.offen) {
      return l10n.statusBis(status.schliesstUm!.alsString);
    }
    final next = status.naechsteOeffnung;
    if (next == null) {
      return l10n.statusKeineZeiten;
    }
    if (next.tageVoraus == 0) {
      return l10n.statusAb(next.von.alsString);
    }
    if (next.tageVoraus == 1) {
      return l10n.statusMorgenAb(next.von.alsString);
    }
    return l10n.statusTagAb(
        wochentagKurz(next.wochentag, l10n), next.von.alsString);
  }

  static String wochentagKurz(Wochentag tag, AppLocalizations l10n) {
    return switch (tag) {
      Wochentag.montag => l10n.tagMoKurz,
      Wochentag.dienstag => l10n.tagDiKurz,
      Wochentag.mittwoch => l10n.tagMiKurz,
      Wochentag.donnerstag => l10n.tagDoKurz,
      Wochentag.freitag => l10n.tagFrKurz,
      Wochentag.samstag => l10n.tagSaKurz,
      Wochentag.sonntag => l10n.tagSoKurz,
    };
  }

  static String wochentagLang(Wochentag tag, AppLocalizations l10n) {
    return switch (tag) {
      Wochentag.montag => l10n.tagMontag,
      Wochentag.dienstag => l10n.tagDienstag,
      Wochentag.mittwoch => l10n.tagMittwoch,
      Wochentag.donnerstag => l10n.tagDonnerstag,
      Wochentag.freitag => l10n.tagFreitag,
      Wochentag.samstag => l10n.tagSamstag,
      Wochentag.sonntag => l10n.tagSonntag,
    };
  }
}
