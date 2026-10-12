import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/l10n/app_localizations.dart';
import 'package:when_open/models/location.dart';
import 'package:when_open/models/opening_day.dart';
import 'package:when_open/models/wochentag.dart';
import 'package:when_open/providers/locations_provider.dart';
import 'package:when_open/widgets/undo_delete.dart';

/// Merkt sich Loeschaufrufe statt Datei-I/O (FakeAsync-Zone, s. widget_test).
class _FakeNotifier extends AppDataNotifier {
  final geloescht = <String>[];

  @override
  Future<WhenOpenData> build() async => const WhenOpenData();

  @override
  Future<void> deleteLocation(String id) async => geloescht.add(id);
}

final _ort = Location(
  id: 'ort-1',
  name: 'Testladen',
  oeffnungszeiten: [
    for (final tag in Wochentag.values) OpeningDay.geschlossen(tag),
  ],
  erstelltAm: DateTime.utc(2026),
  geaendertAm: DateTime.utc(2026),
);

Future<_FakeNotifier> _starte(WidgetTester tester) async {
  final notifier = _FakeNotifier();
  await tester.pumpWidget(ProviderScope(
    overrides: [appDataProvider.overrideWith(() => notifier)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () =>
                loescheMitUndo(context: context, ref: ref, location: _ort),
            child: const Text('löschen'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('löschen'));
  await tester.pump();
  return notifier;
}

void main() {
  testWidgets('loescht nach Ablauf der Frist endgueltig', (tester) async {
    final notifier = await _starte(tester);
    expect(notifier.geloescht, isEmpty);

    // Einblenden abwarten — erst dann laeuft die 5-s-Frist
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(notifier.geloescht, ['ort-1']);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Rückgängig verhindert das Löschen', (tester) async {
    final notifier = await _starte(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SnackBarAction));
    await tester.pumpAndSettle();

    expect(notifier.geloescht, isEmpty);
  });
}
