# Arbeitspaket

## AP-P02 — Datenmodell und JSON-Persistenz

| Feld | Wert |
|---|---|
| **Plan-ID** | P02 |
| **Spec-Referenz** | Datenmodell, Edge Cases (korrupte Datei) |
| **Komponente** | Data-Layer |
| **Agent** | Georg |
| **Geschätzte Größe** | ~800 LOC · ~120K Tokens |
| **Abhängig von** | P01 |
| **Übergabe an** | P03, P04, P05 |

> ⚠️ **Aktualisiert 2026-06-10 (E9, E11, E15):** `OpeningDay` nutzt eine **Zeitblock-Liste** statt `von/bis/pauseVon/pauseBis`. Neue Entität **`Kategorie`** + `kategorien`-Liste in der JSON; `Location.kategorie` ist eine **Kategorie-ID**. JSON-Schema-Version **2.0**. Maßgeblich: AP-Zeile in [`../1.3-scope-entscheidungen.md`](../1.3-scope-entscheidungen.md).

---

## Ziel

Die Dart-Datenklassen `Location` und `OpeningDay` implementieren, JSON-Serialisierung einrichten und einen `LocationRepository` bauen, der Einträge zuverlässig liest, schreibt, löscht und bei korrupter Datei ein Backup anlegt.

---

## Eingaben

- Projektstruktur aus P01 (`lib/models/`, `lib/repositories/`)
- `1.1-spezifikation.md` → Abschnitt "Datenmodell" (Felder, Typen, Pflichtfelder, Beispiel-JSON)
- `1.1-spezifikation.md` → Edge Cases (korrupte JSON-Datei, Backup-Logik)

---

## Aufgaben

1. **`Wochentag`-Enum anlegen** (`lib/models/wochentag.dart`)
   - Werte: `mo, di, mi, do, fr, sa, so`
   - Hilfsmethode: `fromDateTime(DateTime dt) → Wochentag`
   - Hilfsmethode: `anzeigename` → "Montag", "Dienstag" etc. (aus ARB-Strings)

2. **`TimeBlock`- und `OpeningDay`-Klassen implementieren** (`lib/models/opening_day.dart`) — **E9**
   - `TimeBlock`: `von` (TimeOfDay), `bis` (TimeOfDay); JSON ↔ `{ "von": "HH:MM", "bis": "HH:MM" }`
   - `OpeningDay`: `wochentag`, `geoeffnet` (abgeleitet aus `zeiten.isNotEmpty`), **`zeiten` (List\<TimeBlock\>)**
   - Leere `zeiten` = geschlossen; eine Pause = Lücke zwischen zwei Blöcken; mehrere Pausen = mehrere Blöcke
   - `TimeOfDay` ↔ `"HH:MM"`-String (Custom Converter); immutable, `copyWith`

2b. **`Kategorie`-Klasse implementieren** (`lib/models/kategorie.dart`) — **E15**
   - Felder: `id` (UUID), `name`, `farbe?` (Hex-String), `sortierung` (int)
   - JSON-Serialisierung, immutable, `copyWith`

3. **`Location`-Klasse implementieren** (`lib/models/location.dart`)
   - Felder: `id`, `name`, `oeffnungszeiten` (List\<OpeningDay\>, 7 Einträge), `adresse?`, `telefon?`, `googleMapsLink?`, **`kategorie?` (Kategorie-ID, String)**, `erstelltAm`, `geaendertAm`
   - JSON-Serialisierung via `json_serializable` (`@JsonSerializable`)
   - `build_runner` einmalig ausführen: `flutter pub run build_runner build`
   - Immutable, `copyWith`-Methode

4. **`LocationRepository` implementieren** (`lib/repositories/location_repository.dart`)
   - Singleton-Pattern (oder Riverpod-Provider)
   - `Future<List<Location>> getAll()` — JSON-Datei lesen, parsen
   - `Future<void> save(Location location)` — neu anlegen oder aktualisieren, atomar schreiben
   - `Future<void> delete(String id)` — Eintrag entfernen, atomar schreiben
   - `Future<String> exportPath()` — Pfad zur JSON-Datei zurückgeben (für Share-Intent in P09)
   - **Kategorien (E15):** `kategorien`-Liste mitlesen/-schreiben; CRUD `addKategorie / renameKategorie / mergeKategorie(from,to) / deleteKategorie(id)` (Löschen → betroffene Einträge `kategorie = null`)
   - **JSON-Schema-Version `2.0`** (Wurzel: `version`, `kategorien`, `eintraege`)
   - Atomares Schreiben: in temporäre Datei schreiben, dann umbenennen (write-then-rename)
   - Backup-Logik: bei `FormatException` beim Parsen → Originaldatei als `whenopen_backup_[timestamp].json` umbenennen, leere Liste zurückgeben

5. **Riverpod-Provider anlegen** (`lib/providers/locations_provider.dart`)
   - `locationsProvider` — `AsyncNotifierProvider<LocationsNotifier, List<Location>>`
   - Methoden: `add(Location)`, `update(Location)`, `delete(String id)`
   - Lädt beim Start aus Repository, hält Liste im Speicher

6. **Unit-Tests schreiben** (`test/repositories/location_repository_test.dart`)
   - Leere Datei → leere Liste
   - Valide JSON → korrekte Location-Objekte
   - Eintrag speichern und wieder lesen
   - Eintrag löschen
   - Korrupte JSON → Backup wird angelegt, leere Liste zurückgegeben
   - Atomarität: simulierter Absturz während Schreiben → alte Datei unbeschädigt

---

## Lieferobjekt

- `lib/models/wochentag.dart`
- `lib/models/opening_day.dart` + `opening_day.g.dart` (generiert)
- `lib/models/location.dart` + `location.g.dart` (generiert)
- `lib/repositories/location_repository.dart`
- `lib/providers/locations_provider.dart`
- `test/repositories/location_repository_test.dart`

---

## Akzeptanzkriterien

- [ ] `flutter test test/repositories/` läuft grün (alle Testfälle)
- [ ] `Location`-Objekt kann serialisiert und deserialisiert werden ohne Datenverlust
- [ ] `TimeOfDay` wird korrekt als `"HH:MM"` gespeichert und geladen
- [ ] Bei korrupter JSON wird Backup-Datei mit Timestamp angelegt
- [ ] Atomares Schreiben: kein inkonsistenter Zustand bei simuliertem Abbruch
- [ ] `flutter analyze` gibt keine Fehler aus

---

## Hinweise

- `TimeOfDay` hat keinen eingebauten JSON-Converter — Custom Converter als separate Klasse anlegen: `class TimeOfDayConverter implements JsonConverter<TimeOfDay, String>`
- Dateipfad über `path_provider` Package ermitteln (`getApplicationDocumentsDirectory()`) — als weiteres Dependency in pubspec.yaml ergänzen falls nicht in P01 eingetragen
- `json_serializable` generiert `*.g.dart`-Dateien — diese werden ins Repository eingecheckt (kein `.gitignore`-Eintrag dafür)
- Das Datenmodell muss genau den 7 Wochentagen entsprechen — beim Laden einer JSON ohne einen Wochentag: fehlende Tage als `geoeffnet: false` auffüllen
