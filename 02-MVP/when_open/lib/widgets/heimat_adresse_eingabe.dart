import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/nominatim_result.dart';
import '../screens/quick_entry/osm_search_step.dart' show importServiceProvider;
import '../theme/app_theme.dart';

/// Wiederverwendbare Heimatadress-Eingabe (Nominatim-Geocoding, **kein GPS**).
///
/// Genutzt in den Einstellungen und im Erstnutzer-Tutorial. Die Komponente
/// fuehrt nur die Adresssuche und meldet die Auswahl nach oben — ob/wann
/// gespeichert wird, entscheidet der Aufrufer ([onGewaehlt] / [onEntfernen]).
///
/// UX-Redesign 2026-06: **Live-Suche** (Debounce) statt Pflicht-Pfeil — wer
/// tippt, sieht automatisch Treffer. Ein **eindeutiger** Treffer wird direkt
/// übernommen, sodass eine getippte, aber nicht angetippte Adresse nicht mehr
/// still verloren geht. Leere/Fehler werden benannt statt verschluckt.
class HeimatAdresseEingabe extends ConsumerStatefulWidget {
  const HeimatAdresseEingabe({
    super.key,
    required this.adresse,
    required this.hatHeimat,
    required this.onGewaehlt,
    required this.onEntfernen,
  });

  /// Aktuell hinterlegte Adresse (Anzeigetext) oder `null`.
  final String? adresse;

  /// True, wenn bereits nutzbare Koordinaten vorliegen.
  final bool hatHeimat;

  /// Nutzer hat einen Treffer gewaehlt: (Adresstext, lat, lon).
  final void Function(String adresse, double lat, double lon) onGewaehlt;

  /// Nutzer hat die hinterlegte Adresse entfernt.
  final VoidCallback onEntfernen;

  @override
  ConsumerState<HeimatAdresseEingabe> createState() =>
      _HeimatAdresseEingabeState();
}

enum _SuchStatus { leer, sucht, treffer, keineTreffer, fehler }

class _HeimatAdresseEingabeState extends ConsumerState<HeimatAdresseEingabe> {
  final _suchController = TextEditingController();
  Timer? _debounce;
  var _sucht = false;
  List<NominatimResult> _treffer = const [];
  _SuchStatus _status = _SuchStatus.leer;

  @override
  void dispose() {
    _debounce?.cancel();
    _suchController.dispose();
    super.dispose();
  }

  /// Live-Suche: nach kurzer Tipp-Pause automatisch suchen (Nominatim-Policy:
  /// max. 1 Request/s — der Debounce hält das ein).
  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 3) {
      setState(() {
        _treffer = const [];
        _status = _SuchStatus.leer;
      });
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 450), () => _sucheAdresse());
  }

  Future<void> _sucheAdresse() async {
    _debounce?.cancel();
    final query = _suchController.text.trim();
    if (query.length < 3) return;
    setState(() {
      _sucht = true;
      _status = _SuchStatus.sucht;
    });
    List<NominatimResult> ergebnisse;
    try {
      ergebnisse = await ref.read(importServiceProvider).searchPlaces(query);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _sucht = false;
        _treffer = const [];
        _status = _SuchStatus.fehler;
      });
      return;
    }
    if (!mounted) return;
    // Treffer ohne Koordinaten sind als Umkreis-Zentrum unbrauchbar → raus.
    final mitKoord =
        ergebnisse.where((e) => e.lat != null && e.lon != null).toList();
    // Eindeutiger Treffer → direkt übernehmen (kein stiller Verlust mehr).
    if (mitKoord.length == 1) {
      _uebernehmen(mitKoord.single);
      return;
    }
    setState(() {
      _sucht = false;
      _treffer = mitKoord;
      _status =
          mitKoord.isEmpty ? _SuchStatus.keineTreffer : _SuchStatus.treffer;
    });
  }

  void _manuellSuchen() {
    FocusScope.of(context).unfocus();
    _sucheAdresse();
  }

  void _uebernehmen(NominatimResult ergebnis) {
    final lat = ergebnis.lat;
    final lon = ergebnis.lon;
    if (lat == null || lon == null) return;
    widget.onGewaehlt(ergebnis.adresse ?? ergebnis.displayName, lat, lon);
    setState(() {
      _treffer = const [];
      _status = _SuchStatus.leer;
      _sucht = false;
      _suchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.hatHeimat)
          _HeimatKarte(
            adresse: widget.adresse ?? '',
            onEntfernen: widget.onEntfernen,
            entfernenLabel: l10n.einstHeimatEntfernen,
          )
        else
          Text(l10n.einstHeimatKeine,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 12),
        TextField(
          controller: _suchController,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (_) => _manuellSuchen(),
          decoration: InputDecoration(
            hintText: l10n.einstHeimatSuchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _sucht
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: l10n.einstHeimatSuchen,
                    onPressed: _manuellSuchen,
                  ),
          ),
        ),
        if (_status == _SuchStatus.keineTreffer)
          _Hinweis(text: l10n.einstHeimatKeineTreffer)
        else if (_status == _SuchStatus.fehler)
          _Hinweis(text: l10n.einstHeimatSuchfehler),
        for (final ergebnis in _treffer)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined, size: 20),
            title: Text(ergebnis.name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(ergebnis.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            onTap: () => _uebernehmen(ergebnis),
          ),
      ],
    );
  }
}

/// Dezenter Hinweis unter dem Suchfeld (kein Treffer / Fehler).
class _Hinweis extends StatelessWidget {
  const _Hinweis({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
    );
  }
}

class _HeimatKarte extends StatelessWidget {
  const _HeimatKarte({
    required this.adresse,
    required this.onEntfernen,
    required this.entfernenLabel,
  });

  final String adresse;
  final VoidCallback onEntfernen;
  final String entfernenLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(adresse, style: const TextStyle(fontSize: 13)),
          ),
          TextButton(onPressed: onEntfernen, child: Text(entfernenLabel)),
        ],
      ),
    );
  }
}
