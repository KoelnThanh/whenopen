import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Platzhalter aus P01 — wird in P05 durch die echte Hauptliste ersetzt.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(child: Text(l10n.homeLeerTitel)),
    );
  }
}
