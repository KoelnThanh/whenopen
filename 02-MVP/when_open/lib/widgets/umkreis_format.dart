import '../l10n/app_localizations.dart';

/// Einheitliche Umkreis-Beschriftung: „750 m" bzw. „1,5 km".
String umkreisLabel(int meter, AppLocalizations l10n) {
  if (meter < 1000) return l10n.einstUmkreisMeter(meter);
  final km = meter / 1000;
  final text = (km % 1 == 0 ? km.toStringAsFixed(0) : km.toStringAsFixed(1))
      .replaceAll('.', ',');
  return l10n.einstUmkreisKm(text);
}
