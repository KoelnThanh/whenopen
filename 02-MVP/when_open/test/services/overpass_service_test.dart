import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:when_open/models/nominatim_result.dart';
import 'package:when_open/services/overpass_service.dart';

void main() {
  group('Query-Aufbau', () {
    test('Umkreis-Query: around mit opening_hours + out center tags', () {
      final q = OverpassService.baueUmkreisQuery(50.941, 6.958, 1500);
      expect(
        q,
        '[out:json][timeout:25];'
        'nwr[opening_hours](around:1500,50.9410,6.9580);'
        'out center tags;',
      );
    });

    test('Tag-Query: Objekt per Typ+ID', () {
      expect(OverpassService.baueTagQuery('way', 42),
          '[out:json][timeout:25];way(42);out tags;');
    });

    test('Koordinaten mit fester Nachkommastelle (kein Locale-Komma)', () {
      final q = OverpassService.baueUmkreisQuery(7, -1.5, 500);
      expect(q, contains('around:500,7.0000,-1.5000'));
    });
  });

  group('fromOverpassElement (Parsing)', () {
    test('node mit Tags: Name, Adresse, Telefon, Zeiten, Koordinaten', () {
      final r = NominatimResult.fromOverpassElement({
        'type': 'node',
        'id': 1,
        'lat': 50.9,
        'lon': 6.9,
        'tags': {
          'name': 'Apotheke',
          'opening_hours': 'Mo-Fr 08:00-18:00',
          'addr:street': 'Hauptstr',
          'addr:housenumber': '1',
          'addr:postcode': '50667',
          'addr:city': 'Köln',
          'phone': '0221 1',
        },
      });
      expect(r.istLeer, isFalse);
      expect(r.name, 'Apotheke');
      expect(r.oeffnungszeiten, 'Mo-Fr 08:00-18:00');
      expect(r.adresse, 'Hauptstr 1, 50667 Köln');
      expect(r.telefon, '0221 1');
      expect(r.osmType, 'node');
      expect(r.osmId, 1);
      expect(r.lat, 50.9);
      expect(r.lon, 6.9);
    });

    test('way nutzt center fuer die Koordinaten', () {
      final r = NominatimResult.fromOverpassElement({
        'type': 'way',
        'id': 2,
        'center': {'lat': 50.91, 'lon': 6.91},
        'tags': {'name': 'Bäckerei'},
      });
      expect(r.lat, 50.91);
      expect(r.lon, 6.91);
      expect(r.oeffnungszeiten, isNull);
    });

    test('namenloses Element wird als leer markiert', () {
      final r = NominatimResult.fromOverpassElement({
        'type': 'node',
        'id': 3,
        'tags': {'opening_hours': '24/7'},
      });
      expect(r.istLeer, isTrue);
    });
  });

  group('findeUmkreis (Mock-HTTP)', () {
    test('parst Elemente, filtert Namenlose, sortiert nach Name', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.bodyFields['data'], contains('around:1200'));
        return http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 1,
                'lat': 50.9,
                'lon': 6.9,
                'tags': {
                  'name': 'Zahnarzt',
                  'opening_hours': 'Mo 09:00-12:00',
                },
              },
              {
                'type': 'way',
                'id': 2,
                'center': {'lat': 50.91, 'lon': 6.91},
                'tags': {'name': 'Apotheke'},
              },
              {
                'type': 'node',
                'id': 3,
                'lat': 50.92,
                'lon': 6.92,
                'tags': {'opening_hours': '24/7'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = OverpassService(client: client);
      final treffer = await service.findeUmkreis(50.9, 6.9, 1200);

      expect(treffer.map((t) => t.name), ['Apotheke', 'Zahnarzt']);
    });

    test('HTTP-Fehler wirft ClientException', () async {
      final client = MockClient((_) async => http.Response('boom', 504));
      final service = OverpassService(client: client);
      expect(service.findeUmkreis(1, 2, 500), throwsA(isA<http.ClientException>()));
    });
  });

  group('ladeTags (Mock-HTTP)', () {
    test('liefert die Tag-Map des Objekts', () async {
      final client = MockClient((request) async {
        expect(request.bodyFields['data'], contains('node(1)'));
        return http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 1,
                'tags': {'opening_hours': 'Mo 09:00-17:00', 'phone': '123'},
              },
            ],
          }),
          200,
        );
      });

      final tags = await OverpassService(client: client).ladeTags('node', 1);
      expect(tags?['opening_hours'], 'Mo 09:00-17:00');
      expect(tags?['phone'], '123');
    });

    test('leere Antwort ergibt null', () async {
      final client =
          MockClient((_) async => http.Response('{"elements":[]}', 200));
      final tags = await OverpassService(client: client).ladeTags('node', 9);
      expect(tags, isNull);
    });

    test('ungueltiger osmType wird abgewiesen (QL-Injection-Schutz)', () async {
      // Manipulierter osm_type aus der Serverantwort darf die Query nicht
      // veraendern: Lookup wird ohne HTTP-Aufruf abgebrochen.
      final client = MockClient((_) async {
        fail('Bei ungueltigem osmType darf keine Anfrage rausgehen');
      });
      final tags = await OverpassService(client: client)
          .ladeTags('node);out:csv(::id);node', 1);
      expect(tags, isNull);
    });
  });

  group('osmType-Allowlist (hatOsmRef)', () {
    NominatimResult ref(String? typ) => NominatimResult(
          displayName: 'x',
          name: 'x',
          osmType: typ,
          osmId: 1,
        );

    test('gueltige Typen erlauben den Nachlookup', () {
      expect(ref('node').hatOsmRef, isTrue);
      expect(ref('way').hatOsmRef, isTrue);
      expect(ref('relation').hatOsmRef, isTrue);
    });

    test('manipulierter/unbekannter Typ sperrt den Nachlookup', () {
      expect(ref('node);out tags;node').hatOsmRef, isFalse);
      expect(ref('NODE').hatOsmRef, isFalse);
      expect(ref(null).hatOsmRef, isFalse);
    });
  });
}
