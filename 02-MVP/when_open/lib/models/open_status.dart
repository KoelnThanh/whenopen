import 'package:flutter/material.dart' show TimeOfDay, immutable;

import 'wochentag.dart';

/// Naechster Oeffnungszeitpunkt eines geschlossenen Orts.
@immutable
class NextOpening {
  const NextOpening({
    required this.wochentag,
    required this.von,
    required this.tageVoraus,
  });

  final Wochentag wochentag;
  final TimeOfDay von;

  /// 0 = heute (spaeterer Block), 1 = morgen, … 7 = gleicher Tag naechste Woche.
  final int tageVoraus;

  bool get istHeute => tageVoraus == 0;
}

/// Berechneter Zustand eines Orts zu einem Zeitpunkt — nicht persistiert.
@immutable
class OpenStatus {
  const OpenStatus.offen({required TimeOfDay this.schliesstUm})
      : offen = true,
        naechsteOeffnung = null;

  const OpenStatus.geschlossen({this.naechsteOeffnung})
      : offen = false,
        schliesstUm = null;

  final bool offen;

  /// Wenn geoeffnet: `bis` des aktuellen Blocks.
  final TimeOfDay? schliesstUm;

  /// Wenn geschlossen: naechster Oeffnungszeitpunkt (null = nie geoeffnet).
  final NextOpening? naechsteOeffnung;
}

/// Eine Zeile im Android-Widget.
@immutable
class WidgetEntry {
  const WidgetEntry({
    required this.id,
    required this.name,
    required this.statusText,
    required this.offen,
    this.kategorieId,
  });

  final String id;
  final String name;
  final String statusText;
  final bool offen;
  final String? kategorieId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'statusText': statusText,
        'offen': offen,
        if (kategorieId != null) 'kategorieId': kategorieId,
      };

  factory WidgetEntry.fromJson(Map<String, dynamic> json) => WidgetEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        statusText: json['statusText'] as String,
        offen: json['offen'] as bool,
        kategorieId: json['kategorieId'] as String?,
      );
}

/// Aufbereitete Daten fuer das Widget: offen oben, geschlossen unten,
/// beide alphabetisch sortiert.
@immutable
class WidgetData {
  const WidgetData({required this.geoeffnet, required this.geschlossen});

  final List<WidgetEntry> geoeffnet;
  final List<WidgetEntry> geschlossen;

  List<WidgetEntry> get alle => [...geoeffnet, ...geschlossen];

  Map<String, dynamic> toJson() => {
        'geoeffnet': geoeffnet.map((e) => e.toJson()).toList(),
        'geschlossen': geschlossen.map((e) => e.toJson()).toList(),
      };

  factory WidgetData.fromJson(Map<String, dynamic> json) => WidgetData(
        geoeffnet: ((json['geoeffnet'] as List?) ?? const [])
            .map((e) => WidgetEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        geschlossen: ((json['geschlossen'] as List?) ?? const [])
            .map((e) => WidgetEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
