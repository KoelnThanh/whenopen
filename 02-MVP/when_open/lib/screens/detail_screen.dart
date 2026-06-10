import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../models/opening_day.dart';
import '../models/wochentag.dart';
import '../providers/locations_provider.dart';
import '../services/open_status_service.dart';
import '../services/url_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kategorie_dialog.dart';
import '../widgets/undo_delete.dart';

/// Detailansicht (Workflow 4): Wochenuebersicht mit Mehrblock-Zeiten,
/// optionale Felder (tippbar, P07), Bearbeiten und Loeschen mit Undo (E13).
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.locationId});

  final String locationId;

  void _zeigeFehler(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDaten = ref.watch(appDataProvider);
    final locations = ref.watch(locationsProvider);
    final passende = locations.where((l) => l.id == locationId).toList();

    // Eintrag weg (geloescht / veralteter Deep Link) → zurueck zur Liste.
    if (asyncDaten.hasValue && passende.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _zeigeFehler(context, l10n.detailNichtGefunden);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    if (passende.isEmpty) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final location = passende.single;
    final kategorien = ref.watch(kategorienProvider);
    final kategorie = kategorien
        .where((k) => k.id == location.kategorie)
        .toList();
    final heute = Wochentag.fromDateTime(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(location.name, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        children: [
          // Kategorie-Pill (Mockup: catpill)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kategorie.isNotEmpty
                      ? farbeAusHex(kategorie.single.farbe)
                          .withValues(alpha: 0.22)
                      : AppColors.chip,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (kategorie.isNotEmpty
                          ? kategorie.single.name
                          : l10n.sonstige)
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: kategorie.isNotEmpty
                        ? farbeAusHex(kategorie.single.farbe)
                        : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Wochenuebersicht Mo–So
          for (final tag in location.oeffnungszeiten)
            _WochenZeile(
              tag: tag,
              istHeute: tag.wochentag == heute,
              l10n: l10n,
            ),
          // Optionale Felder — nur wenn befuellt (Mockup: field)
          if (location.adresse != null)
            _InfoZeile(
              icon: Icons.place_outlined,
              label: l10n.detailAdresse,
              wert: location.adresse!,
              onTap: () async {
                final ok =
                    await UrlService.openAddressInMaps(location.adresse!);
                if (!ok && context.mounted) {
                  _zeigeFehler(context, l10n.urlFehler);
                }
              },
            ),
          if (location.telefon != null)
            _InfoZeile(
              icon: Icons.phone_outlined,
              label: l10n.detailTelefon,
              wert: location.telefon!,
              onTap: () async {
                final ok = await UrlService.openPhone(location.telefon!);
                if (!ok && context.mounted) {
                  _zeigeFehler(context, l10n.urlKeinTelefon);
                }
              },
            ),
          if (location.googleMapsLink != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await UrlService.openGoogleMaps(
                      location.googleMapsLink);
                  if (!ok && context.mounted) {
                    _zeigeFehler(context, l10n.urlKeinMapsLink);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryInk,
                  backgroundColor: AppColors.chip,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.open_in_new, size: 17),
                label: Text(l10n.detailInMapsOeffnen),
              ),
            ),
          // Aktionen
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/quick-entry?editId=${location.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      backgroundColor: AppColors.chip,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(l10n.detailBearbeiten),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // E13: sofort zurueck zur Liste, dort Undo-SnackBar.
                      final root = context;
                      root.pop();
                      loescheMitUndo(
                          context: root, ref: ref, location: location);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(l10n.detailLoeschen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WochenZeile extends StatelessWidget {
  const _WochenZeile(
      {required this.tag, required this.istHeute, required this.l10n});

  final OpeningDay tag;
  final bool istHeute;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final kurz = OpenStatusService.wochentagKurz(tag.wochentag, l10n);
    final zeiten = tag.geoeffnet
        ? tag.zeiten.map((b) => b.toString()).join(' · ')
        : l10n.statusGeschlossen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: istHeute
            ? AppColors.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        border: const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              istHeute ? '$kurz · ${l10n.detailHeute}' : kurz,
              style: TextStyle(
                fontSize: 13.5,
                color: istHeute ? AppColors.primaryInk : AppColors.muted,
                fontWeight: istHeute ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              zeiten,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: tag.geoeffnet ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoZeile extends StatelessWidget {
  const _InfoZeile({
    required this.icon,
    required this.label,
    required this.wert,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String wert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.muted),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted)),
                Text(wert,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.primaryInk)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
