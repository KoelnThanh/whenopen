import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/app.dart';
import 'package:when_open/models/location.dart';
import 'package:when_open/providers/locations_provider.dart';
import 'package:when_open/repositories/location_repository.dart';

/// Liefert leere Daten ohne Datei-I/O. Wichtig: In der FakeAsync-Zone von
/// testWidgets laeuft ECHTES I/O (auch Directory.createTemp) nie zu Ende —
/// der Test wuerde bei pumpAndSettle haengen.
class _TestNotifier extends AppDataNotifier {
  @override
  Future<WhenOpenData> build() async => const WhenOpenData();
}

void main() {
  testWidgets('App startet und zeigt den Home-Screen', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Kein I/O: Konstruktor speichert nur den Pfad; hatteLadefehler()
        // liest lediglich ein Feld.
        locationRepositoryProvider.overrideWith(
            (ref) async => LocationRepository(Directory.systemTemp)),
        appDataProvider.overrideWith(_TestNotifier.new),
      ],
      child: const WhenOpenApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('WhenOpen'), findsOneWidget);
    expect(find.textContaining('Noch keine Orte gespeichert.'), findsOneWidget);
  });
}
