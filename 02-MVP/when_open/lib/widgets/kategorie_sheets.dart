import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/location.dart';
import '../providers/locations_provider.dart';
import '../theme/app_theme.dart';
import 'kategorie_dialog.dart';

/// Eintrag im Auswahl-Sheet der Hauptliste (E10):
/// null = "Alle Orte", sonst Kategorie-ID ('' = Sonstige).
class AnsichtAuswahl {
  const AnsichtAuswahl.alle()
      : kategorieId = null,
        istAlle = true;
  const AnsichtAuswahl.kategorie(this.kategorieId) : istAlle = false;

  final String? kategorieId;
  final bool istAlle;
}

/// Bottom-Sheet "Anzeigen" (Google-Tasks-Stil, E10): Alle Orte +
/// Kategorien mit Anzahl + Neue Kategorie + Kategorien verwalten.
Future<void> zeigeAnsichtSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String? aktiveKategorieId,
  required bool alleAktiv,
  required ValueChanged<AnsichtAuswahl> onAuswahl,
  required VoidCallback onVerwalten,
}) {
  final l10n = AppLocalizations.of(context)!;
  final kategorien = ref.read(kategorienProvider);
  final locations = ref.read(locationsProvider);

  int anzahlFuer(String? katId) =>
      locations.where((l) => l.kategorie == katId).length;

  return showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.anzeigen,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _SheetOption(
                      label: l10n.alleOrte,
                      punktFarbe: null,
                      selected: alleAktiv,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onAuswahl(const AnsichtAuswahl.alle());
                      },
                    ),
                    for (final kategorie in kategorien)
                      _SheetOption(
                        label: kategorie.name,
                        punktFarbe: farbeAusHex(kategorie.farbe),
                        selected:
                            !alleAktiv && aktiveKategorieId == kategorie.id,
                        anzahl: anzahlFuer(kategorie.id),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onAuswahl(AnsichtAuswahl.kategorie(kategorie.id));
                        },
                      ),
                    if (anzahlFuer(null) > 0)
                      _SheetOption(
                        label: l10n.sonstige,
                        punktFarbe: AppColors.kategorieFallback,
                        selected: !alleAktiv && aktiveKategorieId == '',
                        anzahl: anzahlFuer(null),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onAuswahl(const AnsichtAuswahl.kategorie(''));
                        },
                      ),
                  ],
                ),
              ),
            ),
            _SheetAktion(
              label: '＋ ${l10n.neueKategorie}',
              onTap: () async {
                Navigator.pop(sheetContext);
                final ergebnis = await zeigeNeueKategorieDialog(context);
                if (ergebnis == null) return;
                final kategorie = await ref
                    .read(appDataProvider.notifier)
                    .addKategorie(ergebnis.name, farbe: ergebnis.farbe);
                onAuswahl(AnsichtAuswahl.kategorie(kategorie.id));
              },
            ),
            _SheetAktion(
              label: '⚙ ${l10n.kategorienVerwalten}',
              letzte: true,
              onTap: () {
                Navigator.pop(sheetContext);
                onVerwalten();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Bottom-Sheet "Kategorie aendern" (E15, Lang-Tippen auf Listeneintrag).
Future<void> zeigeKategorieAendernSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Location location,
}) {
  final l10n = AppLocalizations.of(context)!;
  final kategorien = ref.read(kategorienProvider);
  final notifier = ref.read(appDataProvider.notifier);

  Future<void> setze(String? kategorieId) {
    return notifier.updateLocation(location.copyWith(
      kategorie: kategorieId,
      kategorieLoeschen: kategorieId == null,
    ));
  }

  return showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.katAendern,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            Text(location.name,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final kategorie in kategorien)
                      _SheetOption(
                        label: kategorie.name,
                        punktFarbe: farbeAusHex(kategorie.farbe),
                        selected: location.kategorie == kategorie.id,
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await setze(kategorie.id);
                        },
                      ),
                    _SheetOption(
                      label: l10n.sonstige,
                      punktFarbe: AppColors.kategorieFallback,
                      selected: location.kategorie == null,
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await setze(null);
                      },
                    ),
                  ],
                ),
              ),
            ),
            _SheetAktion(
              label: '＋ ${l10n.neueKategorie}',
              letzte: true,
              onTap: () async {
                Navigator.pop(sheetContext);
                final ergebnis = await zeigeNeueKategorieDialog(context);
                if (ergebnis == null) return;
                final kategorie = await notifier.addKategorie(ergebnis.name,
                    farbe: ergebnis.farbe);
                await setze(kategorie.id);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.label,
    required this.punktFarbe,
    required this.selected,
    required this.onTap,
    this.anzahl,
  });

  final String label;
  final Color? punktFarbe;
  final bool selected;
  final int? anzahl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            if (punktFarbe != null)
              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: punktFarbe, shape: BoxShape.circle),
              )
            else
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.muted, width: 2),
                ),
              ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 18, color: AppColors.primaryInk)
            else if (anzahl != null)
              Text('$anzahl',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _SheetAktion extends StatelessWidget {
  const _SheetAktion(
      {required this.label, required this.onTap, this.letzte = false});

  final String label;
  final VoidCallback onTap;
  final bool letzte;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          border: letzte
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 14, color: AppColors.primaryInk)),
      ),
    );
  }
}
