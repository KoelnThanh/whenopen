import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/kategorie.dart';
import '../../theme/app_theme.dart';

/// Schritt 9/10: Kategorie waehlen (E15) — Chips + "Neue Kategorie".
/// Ohne Auswahl landet der Ort unter "Sonstige" (kategorie == null).
class KategorieStep extends StatelessWidget {
  const KategorieStep({
    super.key,
    required this.kategorien,
    required this.gewaehlteId,
    required this.onGewaehlt,
    required this.onNeueKategorie,
  });

  final List<Kategorie> kategorien;
  final String? gewaehlteId;

  /// Auswahl umschalten (erneutes Tippen = abwaehlen → "Sonstige").
  final ValueChanged<String?> onGewaehlt;

  final VoidCallback onNeueKategorie;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final col = context.col;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.qeKategorieTitel,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(l10n.qeKategorieHint,
              style: TextStyle(color: col.muted, fontSize: 13)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kategorie in kategorien)
                _KategorieChip(
                  label: kategorie.name,
                  selected: kategorie.id == gewaehlteId,
                  onTap: () => onGewaehlt(
                      kategorie.id == gewaehlteId ? null : kategorie.id),
                ),
              _NeueKategorieChip(
                label: '＋ ${l10n.neueKategorie}',
                onTap: onNeueKategorie,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.qeKategorieOhne,
              style: TextStyle(color: col.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _KategorieChip extends StatelessWidget {
  const _KategorieChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : col.card,
          border:
              Border.all(color: selected ? AppColors.primary : col.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : col.muted,
          ),
        ),
      ),
    );
  }
}

class _NeueKategorieChip extends StatelessWidget {
  const _NeueKategorieChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: col.card,
          border: Border.all(color: col.line, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, color: col.primaryInk),
        ),
      ),
    );
  }
}
