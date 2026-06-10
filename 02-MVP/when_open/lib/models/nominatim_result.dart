import 'package:flutter/foundation.dart' show immutable;

/// Ein Suchtreffer aus Nominatim (OSM) — Rohdaten vor der Bestaetigung.
@immutable
class NominatimResult {
  const NominatimResult({
    required this.displayName,
    required this.name,
    this.adresse,
    this.telefon,
    this.oeffnungszeiten,
  });

  /// Vollstaendiger Anzeigename (fuer die Trefferliste).
  final String displayName;

  /// Kurzname (Vorbelegung fuer das Namensfeld).
  final String name;

  final String? adresse;
  final String? telefon;

  /// OSM `opening_hours`-Rohwert — noch nicht geparst.
  final String? oeffnungszeiten;

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
    );
  }

  /// Strasse Hausnr, PLZ Ort — nur aus vorhandenen Teilen.
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
}
