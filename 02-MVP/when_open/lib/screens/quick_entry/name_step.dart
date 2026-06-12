import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Schritt 1/10: Name des Orts (Pflichtfeld, Autofokus).
/// Optionaler Einstieg: "Ort aus dem Web uebernehmen" (P08b) —
/// der manuelle Weg bleibt gleichwertig.
class NameStep extends StatelessWidget {
  const NameStep({
    super.key,
    required this.controller,
    required this.zeigeFehler,
    this.onWeiter,
    this.onOsmImport,
    this.onUmkreisImport,
  });

  final TextEditingController controller;
  final bool zeigeFehler;
  final VoidCallback? onWeiter;
  final VoidCallback? onOsmImport;
  final VoidCallback? onUmkreisImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.qeNameTitel,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(l10n.qeNameHint,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => onWeiter?.call(),
            decoration: InputDecoration(
              hintText: l10n.qeNameHint,
              errorText: zeigeFehler ? l10n.qeNamePflicht : null,
            ),
          ),
          if (onOsmImport != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOsmImport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryInk,
                  backgroundColor: AppColors.chip,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.travel_explore, size: 18),
                label: Text(l10n.osmSuchen),
              ),
            ),
          ],
          if (onUmkreisImport != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUmkreisImport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryInk,
                  backgroundColor: AppColors.chip,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.near_me, size: 18),
                label: Text(l10n.umkreisSuchen),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
