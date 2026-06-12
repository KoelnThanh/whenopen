import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/app_einstellungen.dart';
import '../providers/locations_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/heimat_adresse_eingabe.dart';
import '../widgets/umkreis_format.dart';

/// Einstellungen: **Heimatadresse** (einmalig per Nominatim geocodet, lokal
/// gespeichert — keine Standort-Berechtigung) + **Suchradius** fuer die
/// „Orte in der Nähe"-Suche.
class EinstellungenScreen extends ConsumerStatefulWidget {
  const EinstellungenScreen({super.key});

  @override
  ConsumerState<EinstellungenScreen> createState() =>
      _EinstellungenScreenState();
}

class _EinstellungenScreenState extends ConsumerState<EinstellungenScreen> {
  String? _heimatAdresse;
  double? _heimatLat;
  double? _heimatLon;
  late int _umkreis;

  @override
  void initState() {
    super.initState();
    final einst = ref.read(einstellungenProvider);
    _heimatAdresse = einst.heimatAdresse;
    _heimatLat = einst.heimatLat;
    _heimatLon = einst.heimatLon;
    _umkreis = einst.umkreisMeter;
  }

  bool get _hatHeimat => _heimatLat != null && _heimatLon != null;

  void _heimatEntfernen() {
    setState(() {
      _heimatAdresse = null;
      _heimatLat = null;
      _heimatLon = null;
    });
  }

  Future<void> _speichern() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // copyWith auf den aktuellen Einstellungen: bewahrt Felder wie
    // tutorialStatus, die dieser Screen nicht verwaltet.
    final aktuell = ref.read(einstellungenProvider);
    await ref.read(appDataProvider.notifier).setEinstellungen(
          aktuell.copyWith(
            heimatLoeschen: !_hatHeimat,
            heimatAdresse: _heimatAdresse,
            heimatLat: _heimatLat,
            heimatLon: _heimatLon,
            umkreisMeter: _umkreis,
          ),
        );
    messenger.showSnackBar(SnackBar(content: Text(l10n.einstGespeichert)));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.einstTitel)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.einstHeimatTitel,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.einstHeimatInfo,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 12),
            HeimatAdresseEingabe(
              adresse: _heimatAdresse,
              hatHeimat: _hatHeimat,
              onGewaehlt: (adresse, lat, lon) => setState(() {
                _heimatAdresse = adresse;
                _heimatLat = lat;
                _heimatLon = lon;
              }),
              onEntfernen: _heimatEntfernen,
            ),
            const Divider(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.einstUmkreisTitel,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(umkreisLabel(_umkreis, l10n),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryInk)),
              ],
            ),
            Slider(
              value: _umkreis.toDouble(),
              min: AppEinstellungen.minUmkreis.toDouble(),
              max: AppEinstellungen.maxUmkreis.toDouble(),
              divisions:
                  (AppEinstellungen.maxUmkreis - AppEinstellungen.minUmkreis) ~/
                      250,
              label: umkreisLabel(_umkreis, l10n),
              onChanged: (v) => setState(() => _umkreis = (v ~/ 250) * 250),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _speichern,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.einstSpeichern),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(l10n.einstAttribution,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
