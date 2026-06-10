import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/kategorie.dart';
import '../providers/locations_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kategorie_dialog.dart';

/// "Kategorien verwalten" (E15): Umbenennen, Farbe, Zusammenfuehren,
/// Loeschen (mit Vorwarnung), Drag-Sortierung. "Sonstige" ist nicht
/// loeschbar und nicht sortierbar.
class KategorienScreen extends ConsumerWidget {
  const KategorienScreen({super.key});

  Future<void> _bearbeiten(
      BuildContext context, WidgetRef ref, Kategorie kategorie) async {
    final l10n = AppLocalizations.of(context)!;
    final ergebnis = await zeigeNeueKategorieDialog(
      context,
      initialName: kategorie.name,
      initialFarbe: kategorie.farbe,
      titel: l10n.katUmbenennen,
    );
    if (ergebnis == null) return;
    final notifier = ref.read(appDataProvider.notifier);
    if (ergebnis.name != kategorie.name) {
      await notifier.renameKategorie(kategorie.id, ergebnis.name);
    }
    if (ergebnis.farbe != kategorie.farbe) {
      await notifier.setKategorieFarbe(kategorie.id, ergebnis.farbe);
    }
  }

  Future<void> _zusammenfuehren(
      BuildContext context, WidgetRef ref, Kategorie quelle) async {
    final l10n = AppLocalizations.of(context)!;
    final andere = ref
        .read(kategorienProvider)
        .where((k) => k.id != quelle.id)
        .toList();
    if (andere.isEmpty) return;

    final ziel = await showDialog<Kategorie>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.katZiel),
        children: [
          for (final kategorie in andere)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, kategorie),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: farbeAusHex(kategorie.farbe),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(kategorie.name),
                ],
              ),
            ),
        ],
      ),
    );
    if (ziel == null || !context.mounted) return;

    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.katZusammenfuehren),
        content: Text(l10n.katZusammenWarnung(quelle.name, ziel.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.qeAbbrechen),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (bestaetigt != true) return;
    await ref
        .read(appDataProvider.notifier)
        .mergeKategorien(quelle.id, ziel.id);
  }

  Future<void> _loeschen(
      BuildContext context, WidgetRef ref, Kategorie kategorie) async {
    final l10n = AppLocalizations.of(context)!;
    final betroffen = ref
        .read(locationsProvider)
        .where((l) => l.kategorie == kategorie.id)
        .length;

    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${l10n.katLoeschen}: ${kategorie.name}'),
        content:
            betroffen > 0 ? Text(l10n.katLoeschenWarnung(betroffen)) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.qeAbbrechen),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.katLoeschen),
          ),
        ],
      ),
    );
    if (bestaetigt != true) return;
    await ref.read(appDataProvider.notifier).deleteKategorie(kategorie.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final kategorien = ref.watch(kategorienProvider);
    final locations = ref.watch(locationsProvider);

    int anzahl(String? id) =>
        locations.where((l) => l.kategorie == id).length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.katTitel)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ergebnis = await zeigeNeueKategorieDialog(context);
          if (ergebnis == null) return;
          await ref
              .read(appDataProvider.notifier)
              .addKategorie(ergebnis.name, farbe: ergebnis.farbe);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: kategorien.length,
              onReorderItem: (von, nach) async {
                final neu = [...kategorien];
                final element = neu.removeAt(von);
                neu.insert(nach, element);
                await ref
                    .read(appDataProvider.notifier)
                    .setKategorienReihenfolge([for (final k in neu) k.id]);
              },
              footer: _SonstigeZeile(
                  l10n: l10n, anzahl: anzahl(null)),
              itemBuilder: (context, index) {
                final kategorie = kategorien[index];
                final orte = anzahl(kategorie.id);
                return Container(
                  key: ValueKey(kategorie.id),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: farbeAusHex(kategorie.farbe),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(kategorie.name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                              Text(
                                orte == 1 ? l10n.katEinOrt : l10n.katOrte(orte),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.drag_handle,
                              color: Color(0xFF5B626D), size: 20),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Color(0xFF5B626D), size: 20),
                        onSelected: (aktion) {
                          switch (aktion) {
                            case 'bearbeiten':
                              _bearbeiten(context, ref, kategorie);
                            case 'zusammen':
                              _zusammenfuehren(context, ref, kategorie);
                            case 'loeschen':
                              _loeschen(context, ref, kategorie);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: 'bearbeiten',
                              child: Text(l10n.katUmbenennen)),
                          PopupMenuItem(
                              value: 'zusammen',
                              child: Text(l10n.katZusammenfuehren)),
                          PopupMenuItem(
                            value: 'loeschen',
                            child: Text(l10n.katLoeschen,
                                style: const TextStyle(
                                    color: AppColors.danger)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "Sonstige" — automatische Auffang-Kategorie, nicht loeschbar (E15).
class _SonstigeZeile extends StatelessWidget {
  const _SonstigeZeile({required this.l10n, required this.anzahl});

  final AppLocalizations l10n;
  final int anzahl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: const BoxDecoration(
              color: AppColors.kategorieFallback,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.sonstige,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
              Text(
                anzahl > 0
                    ? '${l10n.katSonstigeHint} · ${anzahl == 1 ? l10n.katEinOrt : l10n.katOrte(anzahl)}'
                    : l10n.katSonstigeHint,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
