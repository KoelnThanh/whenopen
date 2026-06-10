import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/location.dart';
import '../providers/locations_provider.dart';

/// IDs, die gerade "weich geloescht" sind (E13): aus der Liste ausgeblendet,
/// aber noch nicht persistent entfernt. Nach Ablauf der SnackBar-Frist
/// (~5 s) wird endgueltig geloescht; "Rueckgaengig" blendet wieder ein.
final ausgeblendeteIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Loescht [location] mit Undo-SnackBar (E13).
void loescheMitUndo({
  required BuildContext context,
  required WidgetRef ref,
  required Location location,
}) {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final ausblenden = ref.read(ausgeblendeteIdsProvider.notifier);
  final daten = ref.read(appDataProvider.notifier);

  ausblenden.update((ids) => {...ids, location.id});

  messenger.hideCurrentSnackBar();
  final snackBar = messenger.showSnackBar(SnackBar(
    content: Text(l10n.geloescht(location.name)),
    duration: const Duration(seconds: 5),
    action: SnackBarAction(
      label: l10n.rueckgaengig.toUpperCase(),
      onPressed: () {
        // Wiederherstellen: nur wieder einblenden, nichts wurde geloescht.
        ausblenden.update((ids) => {...ids}..remove(location.id));
      },
    ),
  ));

  snackBar.closed.then((grund) async {
    if (grund == SnackBarClosedReason.action) return;
    await daten.deleteLocation(location.id);
    ausblenden.update((ids) => {...ids}..remove(location.id));
  });
}
