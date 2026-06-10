import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/nominatim_result.dart';
import '../../models/opening_day.dart';
import '../../services/open_status_service.dart';
import '../../services/opening_hours_parser.dart';
import '../../theme/app_theme.dart';
import 'osm_search_step.dart';

/// Workflow 5, Schritt 2: gefundene Daten pruefen und bestaetigen.
/// Alle Felder bleiben bearbeitbar — der Nutzer hat das letzte Wort.
class OsmConfirmStep extends StatefulWidget {
  const OsmConfirmStep({super.key, required this.ergebnis});

  final NominatimResult ergebnis;

  @override
  State<OsmConfirmStep> createState() => _OsmConfirmStepState();
}

class _OsmConfirmStepState extends State<OsmConfirmStep> {
  late final TextEditingController _name;
  late final TextEditingController _adresse;
  late final TextEditingController _telefon;
  late final List<OpeningDay>? _zeiten;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.ergebnis.name);
    _adresse = TextEditingController(text: widget.ergebnis.adresse ?? '');
    _telefon = TextEditingController(text: widget.ergebnis.telefon ?? '');
    _zeiten = OpeningHoursParser.parse(widget.ergebnis.oeffnungszeiten);
  }

  @override
  void dispose() {
    _name.dispose();
    _adresse.dispose();
    _telefon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.osmBestaetigeTitel)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(l10n.osmBestaetigeHint,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.muted)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l10n.katName),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adresse,
                    decoration: InputDecoration(labelText: l10n.qeAdresse),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _telefon,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l10n.qeTelefon),
                  ),
                  const SizedBox(height: 16),
                  if (_zeiten != null) ...[
                    Text(l10n.osmZeitenErkannt,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.primaryInk)),
                    const SizedBox(height: 8),
                    for (final tag in _zeiten)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                OpenStatusService.wochentagKurz(
                                    tag.wochentag, l10n),
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.muted),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tag.geoeffnet
                                    ? tag.zeiten
                                        .map((b) => b.toString())
                                        .join(' · ')
                                    : l10n.statusGeschlossen,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: tag.geoeffnet
                                      ? AppColors.ink
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else
                    Text(l10n.osmZeitenNichtErkannt,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.warn)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        backgroundColor: AppColors.chip,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(l10n.qeZurueck),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(OsmUebernahme(
                          name: _name.text.trim(),
                          adresse: _adresse.text.trim().isEmpty
                              ? null
                              : _adresse.text.trim(),
                          telefon: _telefon.text.trim().isEmpty
                              ? null
                              : _telefon.text.trim(),
                          zeiten: _zeiten,
                        ));
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(l10n.osmUebernehmen),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
