import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_einstellungen.dart';
import '../models/kategorie.dart';
import '../models/location.dart';
import '../repositories/location_repository.dart';
import '../services/downloads_backup_service.dart';

/// Repository-Provider — in Tests ueberschreibbar (overrideWith).
final locationRepositoryProvider = FutureProvider<LocationRepository>((ref) {
  return LocationRepository.imAppVerzeichnis();
});

/// Nativer Sicherungs-Speicher (Download/WhenOpen) — in Tests ueberschreibbar.
final downloadsBackupServiceProvider =
    Provider<DownloadsBackupService>((ref) => const DownloadsBackupService());

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

  /// Heimatadresse/Umkreis speichern (Schema 2.1).
  Future<void> setEinstellungen(AppEinstellungen einstellungen) async {
    await (await _repo).setEinstellungen(einstellungen);
    await _nachAenderung();
  }

  /// Tutorial-Entscheidung der Erstnutzung dauerhaft speichern
  /// (z. B. „Nein" → [TutorialStatus.abgelehnt], damit nie wieder gefragt wird).
  Future<void> setTutorialStatus(TutorialStatus status) async {
    final aktuell =
        state.valueOrNull?.einstellungen ?? const AppEinstellungen();
    await setEinstellungen(aktuell.copyWith(tutorialStatus: status));
  }

  /// Datierte, teilbare Sicherungskopie für den Teilen-Dialog (P10).
  Future<File> exportKopie() async => (await _repo).exportKopie();

  /// „Sichern": schreibt die aktuellen Daten in den festen, sichtbaren Ordner
  /// `Download/WhenOpen` (überschreibt) und gibt das Ordner-Label zurück.
  Future<String> sichern() async {
    final inhalt = await (await _repo).exportInhalt();
    return ref.read(downloadsBackupServiceProvider).sichern(inhalt);
  }

  /// Inhalt der neuesten Sicherung aus `Download/WhenOpen` (schnelles Laden).
  Future<String?> letzteSicherungInhalt() =>
      ref.read(downloadsBackupServiceProvider).letzteSicherung();

  /// Validiert eine Sicherung ohne zu speichern (für die Import-Vorschau).
  Future<WhenOpenData> pruefeSicherung(String inhalt) async =>
      (await _repo).pruefeSicherung(inhalt);

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

/// App-Einstellungen (Heimatadresse/Umkreis) — Default solange ungeladen.
final einstellungenProvider = Provider<AppEinstellungen>((ref) {
  return ref.watch(appDataProvider).valueOrNull?.einstellungen ??
      const AppEinstellungen();
});

/// True, wenn der Erstnutzer-Tutorial-Dialog angeboten werden soll: Daten
/// geladen, noch keine Eintraege und Tutorial-Status [TutorialStatus.offen].
/// Der Ladefehler-Vorrang (kein Tutorial bei beschaedigter Datei) wird im
/// HomeScreen separat geprueft, weil er nur dem Repository bekannt ist.
final zeigeOnboardingProvider = Provider<bool>((ref) {
  final daten = ref.watch(appDataProvider).valueOrNull;
  if (daten == null) return false;
  return daten.eintraege.isEmpty &&
      daten.einstellungen.tutorialStatus == TutorialStatus.offen;
});
