import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Schritt 1/10: Name des Orts (Pflichtfeld).
///
/// Reines Namensfeld — die Einstiegswege (lokale Suche, Umkreis, manuell)
/// liegen jetzt in der vorgelagerten Methodenauswahl ([StartAuswahlStep]).
/// [autofocus] ist nur dann `true`, wenn der Nutzer bewusst „Manuell" gewählt
/// hat; nach einem Web-Import bleibt die Tastatur zu (Punkt 1).
class NameStep extends StatelessWidget {
  const NameStep({
    super.key,
    required this.controller,
    required this.zeigeFehler,
    this.autofocus = false,
    this.onWeiter,
  });

  final TextEditingController controller;
  final bool zeigeFehler;
  final bool autofocus;
  final VoidCallback? onWeiter;

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
              style: TextStyle(color: context.col.muted, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: autofocus,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => onWeiter?.call(),
            decoration: InputDecoration(
              hintText: l10n.qeNameHint,
              errorText: zeigeFehler ? l10n.qeNamePflicht : null,
            ),
          ),
        ],
      ),
    );
  }
}
