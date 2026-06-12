import 'package:flutter/foundation.dart' show immutable;

/// Ein Suchtreffer aus OSM — Rohdaten vor der Bestaetigung. Quelle ist
/// entweder Nominatim (Textsuche) oder Overpass (Umkreissuche/Tag-Nachlookup).
@immutable
class NominatimResult {
  const NominatimResult({
    required this.displayName,
    required this.name,
    this.adresse,
    this.telefon,
    this.oeffnungszeiten,
    this.osmType,
    this.osmId,
    this.lat,
    this.lon,
  });

  /// Vollstaendiger Anzeigename (fuer die Trefferliste).
  final String displayName;

  /// Kurzname (Vorbelegung fuer das Namensfeld).
  final String name;

  final String? adresse;
  final String? telefon;

  /// OSM `opening_hours`-Rohwert — noch nicht geparst.
  final String? oeffnungszeiten;

  /// OSM-Objekttyp (`node`/`way`/`relation`) und -ID — fuer den
  /// Overpass-Nachlookup der Oeffnungszeiten (Option B).
  final String? osmType;
  final int? osmId;

  /// Koordinaten des Treffers (z. B. zum Setzen der Heimatadresse).
  final double? lat;
  final double? lon;

  /// True, wenn ein Overpass-Tag-Nachlookup moeglich ist.
  bool get hatOsmRef => osmType != null && osmId != null;

  factory NominatimResult.fromJson(Map<String, dynamic> json) {
    final extratags = (json['extratags'] as Map<String, dynamic>?) ?? const {};
    final namedetails =
        (json['namedetails'] as Map<String, dynamic>?) ?? const {};
    final address = (json['address'] as Map<String, dynamic>?) ?? const {};
    final displayName = (json['display_name'] as String?) ?? '';

    return NominatimResult(
      displayName: displayName,
      name: (namedetails['name'] as String?) ??
          (json['name'] as String?) ??
          displayName.split(',').first.trim(),
      adresse: _baueAdresse(address),
      telefon: (extratags['phone'] as String?) ??
          (extratags['contact:phone'] as String?),
      oeffnungszeiten: extratags['opening_hours'] as String?,
      osmType: json['osm_type'] as String?,
      osmId: (json['osm_id'] as num?)?.toInt(),
      lat: double.tryParse('${json['lat']}'),
      lon: double.tryParse('${json['lon']}'),
    );
  }

  /// Ein Overpass-Element (`out center tags`) in einen Treffer wandeln.
  /// Namenlose Objekte werden uebersprungen (`null`).
  factory NominatimResult.fromOverpassElement(Map<String, dynamic> element) {
    final tags = (element['tags'] as Map<String, dynamic>?) ?? const {};
    final name = (tags['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return const NominatimResult._leer();
    }
    // node: lat/lon direkt; way/relation: `center` (durch `out center`).
    double? lat = (element['lat'] as num?)?.toDouble();
    double? lon = (element['lon'] as num?)?.toDouble();
    final center = element['center'] as Map<String, dynamic>?;
    if (center != null) {
      lat ??= (center['lat'] as num?)?.toDouble();
      lon ??= (center['lon'] as num?)?.toDouble();
    }
    final adresse = _baueAdresseAusTags(tags);
    return NominatimResult(
      displayName: adresse ?? name,
      name: name,
      adresse: adresse,
      telefon: (tags['phone'] ?? tags['contact:phone']) as String?,
      oeffnungszeiten: tags['opening_hours'] as String?,
      osmType: element['type'] as String?,
      osmId: (element['id'] as num?)?.toInt(),
      lat: lat,
      lon: lon,
    );
  }

  /// Interner Marker fuer „namenloses Overpass-Element" (wird gefiltert).
  const NominatimResult._leer()
      : displayName = '',
        name = '',
        adresse = null,
        telefon = null,
        oeffnungszeiten = null,
        osmType = null,
        osmId = null,
        lat = null,
        lon = null;

  bool get istLeer => name.isEmpty;

  NominatimResult copyWith({
    String? displayName,
    String? name,
    String? adresse,
    String? telefon,
    String? oeffnungszeiten,
    String? osmType,
    int? osmId,
    double? lat,
    double? lon,
  }) =>
      NominatimResult(
        displayName: displayName ?? this.displayName,
        name: name ?? this.name,
        adresse: adresse ?? this.adresse,
        telefon: telefon ?? this.telefon,
        oeffnungszeiten: oeffnungszeiten ?? this.oeffnungszeiten,
        osmType: osmType ?? this.osmType,
        osmId: osmId ?? this.osmId,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
      );

  /// Strasse Hausnr, PLZ Ort — nur aus vorhandenen Teilen (Nominatim-Adresse).
  static String? _baueAdresse(Map<String, dynamic> address) {
    final strasse = address['road'] as String?;
    final hausnummer = address['house_number'] as String?;
    final plz = address['postcode'] as String?;
    final ort = (address['city'] ?? address['town'] ?? address['village'])
        as String?;

    final zeile1 = [?strasse, ?hausnummer].join(' ');
    final zeile2 = [?plz, ?ort].join(' ');

    final teile = [
      if (zeile1.isNotEmpty) zeile1,
      if (zeile2.isNotEmpty) zeile2,
    ];
    return teile.isEmpty ? null : teile.join(', ');
  }

  /// Adresse aus Overpass-`addr:*`-Tags.
  static String? _baueAdresseAusTags(Map<String, dynamic> tags) {
    final strasse = tags['addr:street'] as String?;
    final hausnummer = tags['addr:housenumber'] as String?;
    final plz = tags['addr:postcode'] as String?;
    final ort = tags['addr:city'] as String?;

    final zeile1 = [?strasse, ?hausnummer].join(' ');
    final zeile2 = [?plz, ?ort].join(' ');

    final teile = [
      if (zeile1.isNotEmpty) zeile1,
      if (zeile2.isNotEmpty) zeile2,
    ];
    return teile.isEmpty ? null : teile.join(', ');
  }
}
