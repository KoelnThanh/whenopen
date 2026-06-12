import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/models/app_einstellungen.dart';
import 'package:when_open/models/location.dart';
import 'package:when_open/models/opening_day.dart';
import 'package:when_open/models/wochentag.dart';
import 'package:when_open/providers/locations_provider.dart';
import 'package:when_open/repositories/location_repository.dart';

Location _testLocation({String id = 'loc-1'}) => Location(
      id: id,
      name: 'Testort',
      oeffnungszeiten: const [
        OpeningDay(wochentag: Wochentag.montag, zeiten: [
          TimeBlock(
              von: TimeOfDay(hour: 9, minute: 0),
              bis: TimeOfDay(hour: 18, minute: 0)),
        ]),
        OpeningDay(wochentag: Wochentag.dienstag, zeiten: []),
        OpeningDay(wochentag: Wochentag.mittwoch, zeiten: []),
        OpeningDay(wochentag: Wochentag.donnerstag, zeiten: []),
        OpeningDay(wochentag: Wochentag.freitag, zeiten: []),
        OpeningDay(wochentag: Wochentag.samstag, zeiten: []),
        OpeningDay(wochentag: Wochentag.sonntag, zeiten: []),
      ],
      erstelltAm: DateTime.utc(2026, 6, 10, 12),
      geaendertAm: DateTime.utc(2026, 6, 10, 12),
    );

void main() {
  late Directory tempDir;
  late LocationRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('whenopen_onb_');
    repo = LocationRepository(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      locationRepositoryProvider.overrideWith((ref) async => repo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('zeigeOnboardingProvider', () {
    test('leere App + Status offen → Onboarding wird angeboten', () async {
      final c = container();
      await c.read(appDataProvider.future);
      expect(c.read(zeigeOnboardingProvider), isTrue);
    });

    test('vorhandene Eintraege → kein Onboarding', () async {
      await repo.saveLocation(_testLocation());
      final c = container();
      await c.read(appDataProvider.future);
      expect(c.read(zeigeOnboardingProvider), isFalse);
    });

    test('Status abgelehnt → kein Onboarding (dauerhaft)', () async {
      final c = container();
      await c.read(appDataProvider.future);
      await c
          .read(appDataProvider.notifier)
          .setTutorialStatus(TutorialStatus.abgelehnt);
      expect(c.read(zeigeOnboardingProvider), isFalse);
    });

    test('Status abgeschlossen → kein Onboarding', () async {
      final c = container();
      await c.read(appDataProvider.future);
      await c
          .read(appDataProvider.notifier)
          .setTutorialStatus(TutorialStatus.abgeschlossen);
      expect(c.read(zeigeOnboardingProvider), isFalse);
    });

    test('setTutorialStatus bleibt nach Neuladen erhalten', () async {
      final c = container();
      await c.read(appDataProvider.future);
      await c
          .read(appDataProvider.notifier)
          .setTutorialStatus(TutorialStatus.abgelehnt);

      // Frischer Container auf demselben Verzeichnis: Persistenz pruefen.
      final c2 = container();
      final daten = await c2.read(appDataProvider.future);
      expect(daten.einstellungen.tutorialStatus, TutorialStatus.abgelehnt);
      expect(c2.read(zeigeOnboardingProvider), isFalse);
    });
  });
}
