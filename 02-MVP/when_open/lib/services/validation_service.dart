import '../l10n/app_localizations.dart';
import '../models/location.dart';
import '../models/opening_day.dart';

enum ValidationFehlerTyp {
  nameFehlt,
  keinTagGeoeffnet,
  vonNachBis,
  bloeckeUeberlappen,
  ungueltigeUrl,
}

class ValidationError {
  const ValidationError({required this.typ, required this.feld});

  final ValidationFehlerTyp typ;

  /// Betroffenes Feld, z.B. "name" oder ein Wochentag-Kuerzel ("mo").
  final String feld;

  String meldung(AppLocalizations l10n) => switch (typ) {
        ValidationFehlerTyp.nameFehlt => l10n.valNameFehlt,
        ValidationFehlerTyp.keinTagGeoeffnet => l10n.valKeinTagOffen,
        ValidationFehlerTyp.vonNachBis => l10n.valVonVorBis,
        ValidationFehlerTyp.bloeckeUeberlappen => l10n.valBloeckeUeberlappen,
        ValidationFehlerTyp.ungueltigeUrl => l10n.valUngueltigeUrl,
      };
}

/// Prueft eine Location vor dem Speichern (Workflow 1, E9).
abstract final class ValidationService {
  static List<ValidationError> validateLocation(Location location) {
    final fehler = <ValidationError>[];

    if (location.name.trim().isEmpty) {
      fehler.add(const ValidationError(
          typ: ValidationFehlerTyp.nameFehlt, feld: 'name'));
    }

    if (!location.oeffnungszeiten.any((t) => t.geoeffnet)) {
      fehler.add(const ValidationError(
          typ: ValidationFehlerTyp.keinTagGeoeffnet, feld: 'oeffnungszeiten'));
    }

    for (final tag in location.oeffnungszeiten) {
      // von < bis je Block
      for (final block in tag.zeiten) {
        if (block.von.inMinuten >= block.bis.inMinuten) {
          fehler.add(ValidationError(
              typ: ValidationFehlerTyp.vonNachBis, feld: tag.wochentag.kuerzel));
        }
      }
      // Bloecke duerfen sich nicht ueberschneiden (angrenzend ist ok)
      final sortiert = [...tag.zeiten]
        ..sort((a, b) => a.von.inMinuten.compareTo(b.von.inMinuten));
      for (var i = 1; i < sortiert.length; i++) {
        if (sortiert[i].von.inMinuten < sortiert[i - 1].bis.inMinuten) {
          fehler.add(ValidationError(
              typ: ValidationFehlerTyp.bloeckeUeberlappen,
              feld: tag.wochentag.kuerzel));
          break;
        }
      }
    }

    final link = location.googleMapsLink;
    if (link != null && link.isNotEmpty && !link.startsWith('https://')) {
      fehler.add(const ValidationError(
          typ: ValidationFehlerTyp.ungueltigeUrl, feld: 'googleMapsLink'));
    }

    return fehler;
  }
}
