import 'package:flutter/material.dart' show TimeOfDay, immutable;

import 'wochentag.dart';

/// Hilfsfunktionen fuer Zeitvergleiche auf Minutenbasis.
extension TimeOfDayMinuten on TimeOfDay {
  int get inMinuten => hour * 60 + minute;

  /// "HH:MM" — Speicher- und Anzeigeformat (24h).
  String get alsString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static TimeOfDay parse(String hhmm) {
    final teile = hhmm.split(':');
    if (teile.length != 2) {
      throw FormatException('Ungueltige Zeit: $hhmm');
    }
    final h = int.parse(teile[0]);
    final m = int.parse(teile[1]);
    if (h < 0 || h > 23 || m < 0 || m > 59) {
      throw FormatException('Zeit ausserhalb des Wertebereichs: $hhmm');
    }
    return TimeOfDay(hour: h, minute: m);
  }
}

/// Ein Oeffnungsblock (E9). Eine Pause ist die Luecke zwischen zwei Bloecken.
@immutable
class TimeBlock {
  const TimeBlock({required this.von, required this.bis});

  final TimeOfDay von;
  final TimeOfDay bis;

  factory TimeBlock.fromJson(Map<String, dynamic> json) => TimeBlock(
        von: TimeOfDayMinuten.parse(json['von'] as String),
        bis: TimeOfDayMinuten.parse(json['bis'] as String),
      );

  Map<String, dynamic> toJson() =>
      {'von': von.alsString, 'bis': bis.alsString};

  TimeBlock copyWith({TimeOfDay? von, TimeOfDay? bis}) =>
      TimeBlock(von: von ?? this.von, bis: bis ?? this.bis);

  @override
  bool operator ==(Object other) =>
      other is TimeBlock && other.von == von && other.bis == bis;

  @override
  int get hashCode => Object.hash(von, bis);

  @override
  String toString() => '${von.alsString}–${bis.alsString}';
}

/// Oeffnungszeiten eines Wochentags (E9: Liste von Zeitbloecken).
/// Leere [zeiten] = geschlossen. [geoeffnet] ist daraus abgeleitet.
@immutable
class OpeningDay {
  const OpeningDay({required this.wochentag, required this.zeiten});

  final Wochentag wochentag;
  final List<TimeBlock> zeiten;

  bool get geoeffnet => zeiten.isNotEmpty;

  factory OpeningDay.geschlossen(Wochentag wochentag) =>
      OpeningDay(wochentag: wochentag, zeiten: const []);

  factory OpeningDay.fromJson(Map<String, dynamic> json) => OpeningDay(
        wochentag: Wochentag.fromKuerzel(json['wochentag'] as String),
        zeiten: ((json['zeiten'] as List?) ?? const [])
            .map((z) => TimeBlock.fromJson(z as Map<String, dynamic>))
            .toList(),
      );

  /// `geoeffnet` wird mitgeschrieben (Schema-Kompatibilitaet), beim Lesen
  /// aber aus [zeiten] abgeleitet.
  Map<String, dynamic> toJson() => {
        'wochentag': wochentag.kuerzel,
        'geoeffnet': geoeffnet,
        'zeiten': zeiten.map((z) => z.toJson()).toList(),
      };

  OpeningDay copyWith({Wochentag? wochentag, List<TimeBlock>? zeiten}) =>
      OpeningDay(
        wochentag: wochentag ?? this.wochentag,
        zeiten: zeiten ?? this.zeiten,
      );
}
