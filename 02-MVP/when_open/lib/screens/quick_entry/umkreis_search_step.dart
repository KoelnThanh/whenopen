import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/nominatim_result.dart';
import '../../providers/locations_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/umkreis_format.dart';
import 'osm_confirm_step.dart';
import 'osm_search_step.dart';

/// „Orte in der Nähe": laedt POIs mit Oeffnungszeiten im Umkreis der in den
/// Einstellungen hinterlegten Heimatadresse (Overpass `around`). **Kein GPS** —
/// die Koordinaten liegen lokal vor, keine Standort-Berechtigung noetig.
class UmkreisSearchStep extends ConsumerStatefulWidget {
  const UmkreisSearchStep({super.key});

  @override
  ConsumerState<UmkreisSearchStep> createState() => _UmkreisSearchStepState();
}

enum _Zustand { laedt, treffer, keineTreffer, fehler }

class _UmkreisSearchStepState extends ConsumerState<UmkreisSearchStep> {
  var _zustand = _Zustand.laedt;
  List<NominatimResult> _ergebnisse = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _suche());
  }

  Future<void> _suche() async {
    final einst = ref.read(einstellungenProvider);
    if (!einst.hatHeimat) {
      setState(() => _zustand = _Zustand.fehler);
      return;
    }
    setState(() => _zustand = _Zustand.laedt);
    try {
      final ergebnisse = await ref.read(overpassServiceProvider).findeUmkreis(
            einst.heimatLat!,
            einst.heimatLon!,
            einst.umkreisMeter,
          );
      if (!mounted) return;
      setState(() {
        _ergebnisse = ergebnisse;
        _zustand =
            ergebnisse.isEmpty ? _Zustand.keineTreffer : _Zustand.treffer;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _zustand = _Zustand.fehler);
    }
  }

  Future<void> _trefferGewaehlt(NominatimResult ergebnis) async {
    final uebernahme = await Navigator.of(context).push<OsmUebernahme>(
      MaterialPageRoute(builder: (_) => OsmConfirmStep(ergebnis: ergebnis)),
    );
    if (uebernahme != null && mounted) {
      Navigator.of(context).pop(uebernahme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final einst = ref.watch(einstellungenProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.umkreisTitel)),
      body: SafeArea(
        child: Column(
          children: [
            if (einst.heimatAdresse != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.near_me,
                        size: 16, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.umkreisRadiusInfo(
                            umkreisLabel(einst.umkreisMeter, l10n),
                            einst.heimatAdresse!),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: _inhalt(l10n)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _inhalt(AppLocalizations l10n) {
    switch (_zustand) {
      case _Zustand.laedt:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.umkreisLaedt,
                  style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        );
      case _Zustand.keineTreffer:
        return _Hinweis(text: l10n.umkreisKeineTreffer);
      case _Zustand.fehler:
        return _Hinweis(text: l10n.umkreisFehler);
      case _Zustand.treffer:
        return ListView.separated(
          itemCount: _ergebnisse.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final ergebnis = _ergebnisse[index];
            final hatZeiten = ergebnis.oeffnungszeiten != null;
            return ListTile(
              title: Text(ergebnis.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: ergebnis.adresse != null
                  ? Text(ergebnis.adresse!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted))
                  : null,
              trailing: Icon(
                hatZeiten ? Icons.schedule : Icons.help_outline,
                size: 18,
                color: hatZeiten ? AppColors.primary : AppColors.muted,
              ),
              onTap: () => _trefferGewaehlt(ergebnis),
            );
          },
        );
    }
  }
}

class _Hinweis extends StatelessWidget {
  const _Hinweis({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted)),
      ),
    );
  }
}
