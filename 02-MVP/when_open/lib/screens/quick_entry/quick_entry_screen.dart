import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Platzhalter aus P01 — wird in P04 durch den echten Schnelleintrag ersetzt.
class QuickEntryScreen extends StatelessWidget {
  const QuickEntryScreen({super.key, this.editId, this.kategorieId});

  /// Wenn gesetzt: Bearbeiten-Modus (P05) statt Neuanlage.
  final String? editId;

  /// Vorbelegte Kategorie, wenn der Flow aus einem Kategorie-Filter startet.
  final String? kategorieId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qeNeuerOrt)),
      body: Center(child: Text(l10n.qeNameTitel)),
    );
  }
}
