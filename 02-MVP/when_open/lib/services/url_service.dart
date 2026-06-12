import 'package:url_launcher/url_launcher.dart';

/// Oeffnet externe Ziele (P07): Google Maps, Karten-App, Telefonwaehler.
/// Kein SDK, kein API-Key — nur URL-Schemes mit Browser-Fallback.
abstract final class UrlService {
  /// Gespeicherten Google-Maps-Link oeffnen (App oder Browser).
  /// Liefert false, wenn der Link fehlt/ungueltig ist oder nicht geoeffnet
  /// werden konnte — die UI zeigt dann eine SnackBar.
  static Future<bool> openGoogleMaps(String? googleMapsLink) async {
    if (googleMapsLink == null || googleMapsLink.trim().isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(googleMapsLink.trim());
    if (uri == null || !uri.isScheme('https')) {
      return false;
    }
    return _starte(uri);
  }

  /// Adresse in der Standard-Karten-App oeffnen (geo:-Scheme),
  /// Fallback: Google-Maps-Suche im Browser.
  static Future<bool> openAddressInMaps(String adresse) async {
    final encoded = Uri.encodeComponent(adresse);
    if (await _starte(Uri.parse('geo:0,0?q=$encoded'))) {
      return true;
    }
    return _starte(Uri.parse('https://maps.google.com/?q=$encoded'));
  }

  /// Telefonwaehler mit der Nummer oeffnen.
  static Future<bool> openPhone(String telefonnummer) async {
    final nummer = telefonnummer.replaceAll(RegExp(r'[\s/()-]'), '');
    return _starte(Uri.parse('tel:$nummer'));
  }

  /// E-Mail-Programm mit vorbereiteter Nachricht oeffnen (`mailto:`).
  /// `betreff` wird korrekt URL-kodiert. Liefert false, wenn kein Mail-Client
  /// vorhanden ist — die UI zeigt dann eine SnackBar.
  static Future<bool> openEmail(String adresse, {String? betreff}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: adresse,
      query: betreff == null
          ? null
          : 'subject=${Uri.encodeComponent(betreff)}',
    );
    return _starte(uri);
  }

  static Future<bool> _starte(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
