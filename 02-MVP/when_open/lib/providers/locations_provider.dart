import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/kategorie.dart';
import '../models/location.dart';
import '../repositories/location_repository.dart';

/// Repository-Provider — in Tests ueberschreibbar (overrideWith).
final locationRepositoryProvider = FutureProvider<LocationRepository>((ref) {
  return LocationRepository.imAppVerzeichnis();
});

/// Zentraler App-Zustand: Kategorien + Eintraege aus der JSON-Datei.
/// Alle Mutationen laufen ueber diesen Notifier, damit UI und
/// Widget-Aktualisierung (P06) einen gemeinsamen Pfad haben.
class AppDataNotifier extends AsyncNotifier<WhenOpenData> {
  /// Hook fuer P06: wird nach jeder Datenaenderung aufgerufen
  /// (Widget-Daten schreiben + Redraw + Alarm neu planen).
  static Future<void> Function(WhenOpenData daten)? onDatenGeaendert;

  @override
  Future<WhenOpenData> build() async {
    final repo = await ref.watch(locationRepositoryProvider.future);
    return repo.laden();
  }

  Future<LocationRepository> get _repo async =>
      ref.read(locationRepositoryProvider.future);

  /// True, wenn beim letzten Laden eine korrupte Datei gesichert wurde.
  Future<bool> hatteLadefehler() async => (await _repo).letzterLadefehler;

  Future<void> _nachAenderung() async {
    final repo = await _repo;
    final daten = await repo.laden();
    state = AsyncData(daten);
    // Widget-Update darf das Speichern nie blockieren oder scheitern
    // lassen — das WorkManager-Netz (E16) faengt verpasste Updates ab.
    try {
      await onDatenGeaendert?.call(daten);
    } catch (_) {
      // bewusst geschluckt
    }
  }

  Future<void> addLocation(Location location) async {
    await (await _repo).saveLocation(location);
    await _nachAenderung();
  }

  Future<void> updateLocation(Location location) async {
    await (await _repo)
        .saveLocation(location.copyWith(geaendertAm: DateTime.now().toUtc()));
    await _nachAenderung();
  }

  Future<void> deleteLocation(String id) async {
    await (await _repo).deleteLocation(id);
    await _nachAenderung();
  }

  Future<Kategorie> addKategorie(String name, {String? farbe}) async {
    final kategorie = await (await _repo).addKategorie(name, farbe: farbe);
    await _nachAenderung();
    return kategorie;
  }

  Future<void> renameKategorie(String id, String neuerName) async {
    await (await _repo).renameKategorie(id, neuerName);
    await _nachAenderung();
  }

  Future<void> setKategorieFarbe(String id, String? farbe) async {
    await (await _repo).setKategorieFarbe(id, farbe);
    await _nachAenderung();
  }

  Future<void> mergeKategorien(String vonId, String nachId) async {
    await (await _repo).mergeKategorien(vonId, nachId);
    await _nachAenderung();
  }

  Future<void> deleteKategorie(String id) async {
    await (await _repo).deleteKategorie(id);
    await _nachAenderung();
  }

  Future<void> setKategorienReihenfolge(List<String> ids) async {
    await (await _repo).setKategorienReihenfolge(ids);
    await _nachAenderung();
  }

  Future<String> exportPath() async => (await _repo).exportPath();

  /// Datierte, teilbare Sicherungskopie (P10).
  Future<File> exportKopie() async => (await _repo).exportKopie();

  /// Wiederherstellen aus JSON; lädt danach Zustand + Widget neu.
  Future<void> importJson(String inhalt) async {
    await (await _repo).importJson(inhalt);
    await _nachAenderung();
  }
}

final appDataProvider =
    AsyncNotifierProvider<AppDataNotifier, WhenOpenData>(AppDataNotifier.new);

/// Bequemer Zugriff auf die sortierte Kategorienliste.
final kategorienProvider = Provider<List<Kategorie>>((ref) {
  final daten = ref.watch(appDataProvider).valueOrNull;
  if (daten == null) return const [];
  final sortiert = [...daten.kategorien]
    ..sort((a, b) => a.sortierung.compareTo(b.sortierung));
  return sortiert;
});

/// Bequemer Zugriff auf alle Eintraege (alphabetisch).
final locationsProvider = Provider<List<Location>>((ref) {
  final daten = ref.watch(appDataProvider).valueOrNull;
  if (daten == null) return const [];
  final sortiert = [...daten.eintraege]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return sortiert;
});
