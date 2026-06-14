import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/models/opening_day.dart';
import 'package:when_open/models/wochentag.dart';
import 'package:when_open/services/opening_hours_parser.dart';

void main() {
  OpeningDay tag(List<OpeningDay> woche, Wochentag w) =>
      woche.firstWhere((t) => t.wochentag == w);

  test('Mo-Fr 09:00-18:00 → Werktage geoeffnet, Wochenende zu', () {
    final woche = OpeningHoursParser.parse('Mo-Fr 09:00-18:00')!;
    expect(woche, hasLength(7));
    expect(tag(woche, Wochentag.montag).zeiten, [
      const TimeBlock(
          von: TimeOfDay(hour: 9, minute: 0),
          bis: TimeOfDay(hour: 18, minute: 0)),
    ]);
    expect(tag(woche, Wochentag.freitag).geoeffnet, isTrue);
    expect(tag(woche, Wochentag.samstag).geoeffnet, isFalse);
    expect(tag(woche, Wochentag.sonntag).geoeffnet, isFalse);
  });

  test('Mo-Fr 09:00-18:00; Sa 10:00-14:00 → Samstag eigene Zeiten', () {
    final woche =
        OpeningHoursParser.parse('Mo-Fr 09:00-18:00; Sa 10:00-14:00')!;
    expect(tag(woche, Wochentag.samstag).zeiten.single,
        const TimeBlock(
            von: TimeOfDay(hour: 10, minute: 0),
            bis: TimeOfDay(hour: 14, minute: 0)));
    expect(tag(woche, Wochentag.sonntag).geoeffnet, isFalse);
  });

  test('Mo-Sa 09:00-20:00; Su off → Sonntag explizit zu', () {
    final woche = OpeningHoursParser.parse('Mo-Sa 09:00-20:00; Su off')!;
    expect(tag(woche, Wochentag.samstag).geoeffnet, isTrue);
    expect(tag(woche, Wochentag.sonntag).geoeffnet, isFalse);
  });

  test('09:00-18:00 ohne Wochentag → alle Tage geoeffnet', () {
    final woche = OpeningHoursParser.parse('09:00-18:00')!;
    for (final w in Wochentag.values) {
      expect(tag(woche, w).geoeffnet, isTrue, reason: w.name);
    }
  });

  test('Mo-Fr 09:00-12:00,14:00-18:00 → zwei Bloecke (Mittagspause, E9)',
      () {
    final woche =
        OpeningHoursParser.parse('Mo-Fr 09:00-12:00,14:00-18:00')!;
    final montag = tag(woche, Wochentag.montag);
    expect(montag.zeiten, hasLength(2));
    expect(montag.zeiten[0].bis, const TimeOfDay(hour: 12, minute: 0));
    expect(montag.zeiten[1].von, const TimeOfDay(hour: 14, minute: 0));
  });

  test('Tagesliste Mo,We 09:00-12:00 → nur Mo und Mi', () {
    final woche = OpeningHoursParser.parse('Mo,We 09:00-12:00')!;
    expect(tag(woche, Wochentag.montag).geoeffnet, isTrue);
    expect(tag(woche, Wochentag.dienstag).geoeffnet, isFalse);
    expect(tag(woche, Wochentag.mittwoch).geoeffnet, isTrue);
  });

  test('Kleinschreibung und Leerraum werden toleriert', () {
    final woche = OpeningHoursParser.parse(' mo-fr  09:00 - 18:00 ');
    expect(woche, isNotNull);
    expect(tag(woche!, Wochentag.montag).geoeffnet, isTrue);
  });

  test('unbekanntes Format → null (kein Crash)', () {
    expect(OpeningHoursParser.parse('Mo-Fr 09:00-18:00; PH off'), isNull);
    expect(OpeningHoursParser.parse('24/7'), isNull);
    expect(OpeningHoursParser.parse('sunrise-sunset'), isNull);
    expect(OpeningHoursParser.parse('Mo[1] 10:00-12:00'), isNull);
  });

  test('leerer String → null', () {
    expect(OpeningHoursParser.parse(''), isNull);
    expect(OpeningHoursParser.parse('   '), isNull);
  });

  test('uebermaessig langer Rohwert → null (ReDoS-Schutz)', () {
    // Untrusted Quelle (OSM-Tag/Import): eine pathologische Eingabe darf den
    // Regex nicht in katastrophales Backtracking treiben. Jenseits der Grenze
    // wird ohne Match abgebrochen.
    final lang = '${'mo-fr 09:00-18:00,' * 60} ';
    expect(lang.length, greaterThan(256));
    expect(OpeningHoursParser.parse(lang), isNull);
  });
}
