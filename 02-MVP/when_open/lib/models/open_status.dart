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
