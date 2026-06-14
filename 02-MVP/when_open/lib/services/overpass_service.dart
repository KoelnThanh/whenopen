import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nominatim_result.dart';

/// Umkreissuche und Tag-Nachlookup ueber die **Overpass API** (OSM).
///
/// Anders als Nominatim (Geocoder: Text→Ort) beantwortet Overpass raeumliche
/// Abfragen ueber OSM-Tags — das richtige Werkzeug fuer „alle Orte mit
/// Oeffnungszeiten im Umkreis". Datenquelle: © OpenStreetMap-Mitwirkende (ODbL).
///
/// Fair-Use der oeffentlichen Server: identifizierender User-Agent ist Pflicht,
/// Timeout begrenzen, pro Nutzung nur eine Abfrage, Ergebnisse cachen.
class OverpassService {
  OverpassService({http.Client? client, this.endpoint = standardEndpoint})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String endpoint;

  static const standardEndpoint =
      'https://overpass-api.de/api/interpreter';
  // Identifizierender Kontakt per Projekt-Link statt privater Mail-Adresse
  // (geht bei jeder Anfrage an den Overpass-Betreiber).
  static const _userAgent =
      'WhenOpen/1.0 (+https://github.com/KoelnThanh/whenopen)';
  static const _timeout = Duration(seconds: 30);

  /// Alle POIs mit gesetzten Oeffnungszeiten im Umkreis [radiusMeter] um
  /// [lat]/[lon], alphabetisch nach Name. Namenlose Objekte fallen weg.
  Future<List<NominatimResult>> findeUmkreis(
      double lat, double lon, int radiusMeter) async {
    final elemente = await _frage(baueUmkreisQuery(lat, lon, radiusMeter));
    final ergebnisse = [
      for (final e in elemente)
        NominatimResult.fromOverpassElement(e as Map<String, dynamic>),
    ].where((r) => !r.istLeer).toList();
    ergebnisse.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return ergebnisse;
  }

  /// Laedt die OSM-Tags eines einzelnen Objekts nach (Option B: fehlende
  /// Oeffnungszeiten nach einer Nominatim-Auswahl ergaenzen). `null`, wenn
  /// nichts gefunden wurde.
  Future<Map<String, dynamic>?> ladeTags(String osmType, int osmId) async {
    // Allowlist: nur echte OSM-Objekttypen in die per String-Interpolation
    // aufgebaute Overpass-QL lassen (verhindert Query-Injection ueber einen
    // manipulierten osm_type). osmId ist als int bereits unkritisch.
    if (!NominatimResult.osmTypen.contains(osmType)) return null;
    final elemente = await _frage(baueTagQuery(osmType, osmId));
    if (elemente.isEmpty) return null;
    final tags = (elemente.first as Map<String, dynamic>)['tags'];
    return tags is Map<String, dynamic> ? tags : null;
  }

  /// Overpass-QL fuer die Umkreissuche (sichtbar fuer Tests).
  static String baueUmkreisQuery(double lat, double lon, int radiusMeter) {
    final umkreis = '$radiusMeter,${_koord(lat)},${_koord(lon)}';
    return '[out:json][timeout:25];'
        'nwr[opening_hours](around:$umkreis);'
        'out center tags;';
  }

  /// Overpass-QL fuer den Tag-Nachlookup eines Objekts (sichtbar fuer Tests).
  static String baueTagQuery(String osmType, int osmId) {
    return '[out:json][timeout:25];$osmType($osmId);out tags;';
  }

  /// Feste Nachkommastellen — kein Locale-Komma, keine Exponentialform.
  /// Bewusst nur 4 Stellen (~11 m): genau genug fuer eine 250–5000-m-
  /// Umkreissuche, gibt aber die Heimat-/Aufenthaltsposition nicht
  /// gebaeudescharf an den Overpass-Betreiber weiter (Privacy).
  static String _koord(double v) => v.toStringAsFixed(4);

  Future<List<dynamic>> _frage(String query) async {
    final antwort = await _client
        .post(
          Uri.parse(endpoint),
          headers: {
            'User-Agent': _userAgent,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'data': query},
        )
        .timeout(_timeout);
    if (antwort.statusCode != 200) {
      throw http.ClientException(
          'Overpass antwortete mit ${antwort.statusCode}', Uri.parse(endpoint));
    }
    final json =
        jsonDecode(utf8.decode(antwort.bodyBytes)) as Map<String, dynamic>;
    return (json['elements'] as List?) ?? const [];
  }
}
