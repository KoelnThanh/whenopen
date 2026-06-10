import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/nominatim_result.dart';
import '../../models/opening_day.dart';
import '../../services/nominatim_service.dart';
import '../../theme/app_theme.dart';
import 'osm_confirm_step.dart';

/// Austauschbarer Import-Dienst (E2) — in Tests ueberschreibbar.
final importServiceProvider =
    Provider<ImportService>((ref) => NominatimService());

/// Vom Nutzer bestaetigte Uebernahme-Daten fuer den Schnelleintrag.
class OsmUebernahme {
  const OsmUebernahme({
    required this.name,
    this.adresse,
    this.telefon,
    this.zeiten,
  });

  final String name;
  final String? adresse;
  final String? telefon;
  final List<OpeningDay>? zeiten;
}

/// Workflow 5, Schritt 1: Ort suchen (Debounce 500 ms, max. 5 Treffer).
/// Der manuelle Eintrag bleibt jederzeit erreichbar.
class OsmSearchStep extends ConsumerStatefulWidget {
  const OsmSearchStep({super.key});

  @override
  ConsumerState<OsmSearchStep> createState() => _OsmSearchStepState();
}

enum _SuchZustand { leer, laedt, treffer, keineTreffer, fehler }

class _OsmSearchStepState extends ConsumerState<OsmSearchStep> {
  final _controller = TextEditingController();
  Timer? _debounce;
  var _zustand = _SuchZustand.leer;
  List<NominatimResult> _ergebnisse = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _eingabeGeaendert(String text) {
    _debounce?.cancel();
    if (text.trim().length < 3) {
      setState(() => _zustand = _SuchZustand.leer);
      return;
    }
    // Nominatim Usage Policy: max. 1 Request/s → 500 ms Debounce.
    _debounce = Timer(const Duration(milliseconds: 500), () => _suche(text));
  }

  Future<void> _suche(String query) async {
    setState(() => _zustand = _SuchZustand.laedt);
    try {
      final ergebnisse =
          await ref.read(importServiceProvider).searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _ergebnisse = ergebnisse;
        _zustand = ergebnisse.isEmpty
            ? _SuchZustand.keineTreffer
            : _SuchZustand.treffer;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _zustand = _SuchZustand.fehler);
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.osmSuchTitel)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _eingabeGeaendert,
                decoration: InputDecoration(
                  hintText: l10n.osmSuchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
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
                  child: Text(l10n.osmManuell),
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
      case _SuchZustand.leer:
        return const SizedBox.shrink();
      case _SuchZustand.laedt:
        return const Center(child: CircularProgressIndicator());
      case _SuchZustand.keineTreffer:
        return _Hinweis(text: l10n.osmKeineTreffer);
      case _SuchZustand.fehler:
        return _Hinweis(text: l10n.osmFehler);
      case _SuchZustand.treffer:
        return ListView.separated(
          itemCount: _ergebnisse.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final ergebnis = _ergebnisse[index];
            return ListTile(
              title: Text(ergebnis.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                ergebnis.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.muted),
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
