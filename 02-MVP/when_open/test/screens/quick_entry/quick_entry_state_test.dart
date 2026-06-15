import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/models/location.dart';
import 'package:when_open/models/opening_day.dart';
import 'package:when_open/models/wochentag.dart';
import 'package:when_open/screens/quick_entry/quick_entry_state.dart';

TimeBlock _b(int vonH, int bisH) => TimeBlock(
      von: TimeOfDay(hour: vonH, minute: 0),
      bis: TimeOfDay(hour: bisH, minute: 0),
    );

void main() {
  group('QuickEntryState — Wochen-Editor (UX-Redesign)', () {
    test('Neuanlage: nichts festgelegt, 4 Schritte', () {
      final s = QuickEntryState();
      expect(QuickEntryState.schritteGesamt, 4);
      expect(s.festgelegt, isEmpty);
      expect(s.zeiten[Wochentag.montag], isEmpty);
    });

    test('naechsterUnbestimmter: ohne Festlegung folgt der nächste Tag', () {
      final s = QuickEntryState();
      expect(s.naechsterUnbestimmter(Wochentag.montag), Wochentag.dienstag);
    });

    test('naechsterUnbestimmter: überspringt festgelegte Tage', () {
      final s = QuickEntryState();
      s.festgelegt.addAll([Wochentag.dienstag, Wochentag.mittwoch]);
      expect(s.naechsterUnbestimmter(Wochentag.montag), Wochentag.donnerstag);
    });

    test('naechsterUnbestimmter: am Sonntag gibt es keinen mehr', () {
      final s = QuickEntryState();
      expect(s.naechsterUnbestimmter(Wochentag.sonntag), isNull);
    });

    test('vorschlagFuer: letzter geöffneter Tag, überspringt geschlossene', () {
      final s = QuickEntryState();
      s.zeiten[Wochentag.montag] = [_b(11, 23)];
      s.festgelegt.addAll([Wochentag.montag, Wochentag.dienstag]); // Di leer = zu
      // Vorschlag für Mittwoch ist Montag (Dienstag ist geschlossen).
      expect(s.vorschlagFuer(Wochentag.mittwoch), [_b(11, 23)]);
    });

    test('Bearbeiten: alle 7 Tage gelten als festgelegt', () {
      final ort = Location(
        id: 'x',
        name: 'Test',
        oeffnungszeiten: [
          for (final w in Wochentag.values)
            OpeningDay(
                wochentag: w,
                zeiten: w == Wochentag.montag ? [_b(9, 18)] : const []),
        ],
        erstelltAm: DateTime.utc(2026),
        geaendertAm: DateTime.utc(2026),
      );
      final s = QuickEntryState.fromLocation(ort);
      expect(s.festgelegt, containsAll(Wochentag.values));
      // Beim Bearbeiten ist kein Tag „noch festzulegen".
      expect(s.naechsterUnbestimmter(Wochentag.montag), isNull);
    });
  });
}
