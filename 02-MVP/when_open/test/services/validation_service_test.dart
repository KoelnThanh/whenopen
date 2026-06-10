import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/models/location.dart';
import 'package:when_open/models/opening_day.dart';
import 'package:when_open/models/wochentag.dart';
import 'package:when_open/services/validation_service.dart';

TimeBlock _block(int vonH, int bisH) => TimeBlock(
      von: TimeOfDay(hour: vonH, minute: 0),
      bis: TimeOfDay(hour: bisH, minute: 0),
    );

Location _ort({
  String name = 'Testort',
  Map<Wochentag, List<TimeBlock>> woche = const {},
  String? googleMapsLink,
}) {
  return Location(
    id: 'test',
    name: name,
    oeffnungszeiten: woche.entries
        .map((e) => OpeningDay(wochentag: e.key, zeiten: e.value))
        .toList(),
    googleMapsLink: googleMapsLink,
    erstelltAm: DateTime.utc(2026),
    geaendertAm: DateTime.utc(2026),
  );
}

void main() {
  final gueltigeWoche = {
    Wochentag.montag: [_block(9, 18)],
  };

  test('valide Location: keine Fehler', () {
    final fehler = ValidationService.validateLocation(_ort(
      woche: gueltigeWoche,
      googleMapsLink: 'https://maps.google.com/?cid=1',
    ));
    expect(fehler, isEmpty);
  });

  test('leerer Name: Fehler nameFehlt', () {
    final fehler = ValidationService.validateLocation(
        _ort(name: '   ', woche: gueltigeWoche));
    expect(fehler.map((f) => f.typ), contains(ValidationFehlerTyp.nameFehlt));
  });

  test('kein einziger geoeffneter Tag: Fehler keinTagGeoeffnet', () {
    final fehler = ValidationService.validateLocation(_ort(woche: {}));
    expect(fehler.map((f) => f.typ),
        contains(ValidationFehlerTyp.keinTagGeoeffnet));
  });

  test('von nach bis: Fehler vonNachBis', () {
    final fehler = ValidationService.validateLocation(_ort(woche: {
      Wochentag.montag: [_block(18, 9)],
    }));
    expect(fehler.map((f) => f.typ), contains(ValidationFehlerTyp.vonNachBis));
  });

  test('von gleich bis: Fehler vonNachBis', () {
    final fehler = ValidationService.validateLocation(_ort(woche: {
      Wochentag.montag: [_block(9, 9)],
    }));
    expect(fehler.map((f) => f.typ), contains(ValidationFehlerTyp.vonNachBis));
  });

  test('ueberlappende Bloecke: Fehler bloeckeUeberlappen (E9)', () {
    final fehler = ValidationService.validateLocation(_ort(woche: {
      Wochentag.montag: [_block(9, 14), _block(13, 18)],
    }));
    expect(fehler.map((f) => f.typ),
        contains(ValidationFehlerTyp.bloeckeUeberlappen));
  });

  test('angrenzende Bloecke (bis == von) sind erlaubt', () {
    final fehler = ValidationService.validateLocation(_ort(woche: {
      Wochentag.montag: [_block(9, 13), _block(13, 18)],
    }));
    expect(fehler, isEmpty);
  });

  test('unsortierte, aber gueltige Bloecke sind erlaubt', () {
    final fehler = ValidationService.validateLocation(_ort(woche: {
      Wochentag.montag: [_block(14, 18), _block(9, 12)],
    }));
    expect(fehler, isEmpty);
  });

  test('Maps-Link ohne https: Fehler ungueltigeUrl (P07)', () {
    final fehler = ValidationService.validateLocation(_ort(
      woche: gueltigeWoche,
      googleMapsLink: 'http://maps.google.com',
    ));
    expect(
        fehler.map((f) => f.typ), contains(ValidationFehlerTyp.ungueltigeUrl));
  });

  test('leerer Maps-Link ist erlaubt (optionales Feld)', () {
    final fehler =
        ValidationService.validateLocation(_ort(woche: gueltigeWoche));
    expect(fehler, isEmpty);
  });
}
