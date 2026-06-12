import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nominatim_result.dart';

/// Austauschbares Import-Interface (E2): heute Nominatim, in v2 ggf.
/// HERE Maps o.ae. Die App funktioniert vollstaendig ohne Import.
abstract class ImportService {
  Future<List<NominatimResult>> searchPlaces(String query);
}

/// OSM/Nominatim-Suche (E2). Usage Policy: max. 1 Request/s, User-Agent
/// mit Kontakt ist Pflicht — Debounce in der UI (500 ms) haelt das ein.
class NominatimService implements ImportService {
  NominatimService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _userAgent = 'WhenOpen/1.0 (contact: koeln.thanh@gmail.com)';
  static const _timeout = Duration(seconds: 5);

  @override
  Future<List<NominatimResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return const [];

    // Option A (Tuning): auf Deutschland eingrenzen, deutsche Namen, POIs
    // priorisieren (hoehere opening_hours-Chance), etwas mehr Treffer.
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query.trim(),
      'format': 'jsonv2',
      'extratags': '1',
      'addressdetails': '1',
      'namedetails': '1',
      'countrycodes': 'de',
      'accept-language': 'de',
      'layer': 'poi,address',
      'limit': '8',
    });

    final antwort = await _client
        .get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout);
    if (antwort.statusCode != 200) {
      throw http.ClientException(
          'Nominatim antwortete mit ${antwort.statusCode}', uri);
    }

    final json = jsonDecode(utf8.decode(antwort.bodyBytes)) as List;
    return json
        .map((e) => NominatimResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
