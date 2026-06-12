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

class _HeimatAdresseEingabeState extends ConsumerState<HeimatAdresseEingabe> {
  final _suchController = TextEditingController();
  var _sucht = false;
  List<NominatimResult> _suchErgebnisse = const [];

  @override
  void dispose() {
    _suchController.dispose();
    super.dispose();
  }

  Future<void> _sucheAdresse() async {
    final query = _suchController.text.trim();
    if (query.length < 3) return;
    FocusScope.of(context).unfocus();
    setState(() => _sucht = true);
    try {
      final ergebnisse =
          await ref.read(importServiceProvider).searchPlaces(query);
      if (!mounted) return;
      setState(() => _suchErgebnisse = ergebnisse);
    } on Exception {
      if (!mounted) return;
      setState(() => _suchErgebnisse = const []);
    } finally {
      if (mounted) setState(() => _sucht = false);
    }
  }

  void _gewaehlt(NominatimResult ergebnis) {
    final lat = ergebnis.lat;
    final lon = ergebnis.lon;
    // Ohne Koordinaten als Umkreis-Zentrum unbrauchbar — Treffer ignorieren.
    if (lat == null || lon == null) return;
    widget.onGewaehlt(ergebnis.adresse ?? ergebnis.displayName, lat, lon);
    setState(() {
      _suchErgebnisse = const [];
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
          onSubmitted: (_) => _sucheAdresse(),
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
                    onPressed: _sucheAdresse,
                  ),
          ),
        ),
        for (final ergebnis in _suchErgebnisse)
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
            onTap: () => _gewaehlt(ergebnis),
          ),
      ],
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
