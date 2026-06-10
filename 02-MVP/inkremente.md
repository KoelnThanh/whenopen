# Inkrement-Protokoll — WhenOpen MVP

Dokumentation je Arbeitspaket: Was gebaut / Was fehlt / Was gelernt.
App-Code: [`when_open/`](when_open/) · Arbeitspakete: [`../01-Konzept/arbeitspakete/`](../01-Konzept/arbeitspakete/)

---

## P01 — Projektstruktur & Setup (2026-06-10)

**Was gebaut:**
- Flutter-Projekt `when_open` (org `com.whenopen`, nur Android), minSdk 26 (E4)
- Alle Dependencies: go_router, flutter_riverpod, home_widget, json_serializable,
  uuid, http, intl, path_provider, url_launcher, share_plus,
  android_alarm_manager_plus + workmanager (E16)
- go_router mit Routen `/`, `/detail/:id`, `/quick-entry`, `/open/:id` (Deep-Link-Redirect)
- Deep-Link-Intent-Filter (`whenopen://`) und `<queries>`-Block (https/tel/geo) im Manifest
- i18n: `l10n.yaml` + `lib/l10n/app_de.arb` (~100 Strings vorab), `gen-l10n` aktiv
- Dunkles Material-3-Theme nach Mockup-Farbwelt (`lib/theme/app_theme.dart`)
- Smoke-Test: App läuft auf Emulator Pixel_API35 (Screenshot verifiziert), `flutter analyze` sauber

**Was fehlt:** echte Screens (P04/P05), Widget-Konfiguration in `android/` (P06).

**Was gelernt:**
- Toolchain war komplett vorhanden, nur nicht im PATH (`C:\flutter\bin\flutter.bat` direkt aufrufen)
- PowerShell `>`-Redirect zerstört Binärdaten (Screenshot) → `adb shell screencap` + `adb pull`
- Flutter 3.44 warnt bei Plugins mit eigenem Kotlin-Gradle-Plugin (alarm_manager, home_widget,
  workmanager, share_plus) — künftige Flutter-Versionen brauchen aktualisierte Plugin-Versionen

## P02 — Datenmodell & JSON-Persistenz (2026-06-10)

**Was gebaut:**
- `Wochentag` (JSON "mo".."so"; Dart-Namen ausgeschrieben, da `do` reserviert ist)
- `TimeBlock` + `OpeningDay` mit Zeitblock-Liste (E9), manuelle JSON-Konvertierung "HH:MM"
- `Kategorie` (E15) und `Location` via json_serializable; `WhenOpenData` als Schema-2.0-Wurzel
- `LocationRepository`: CRUD, atomares Schreiben (write-then-rename), Backup bei korrupter
  Datei (`whenopen_backup_<timestamp>.json`), Kategorie-CRUD inkl. merge/delete→Sonstige,
  fehlende Wochentage werden beim Konstruieren aufgefüllt
- Riverpod: `appDataProvider` (AsyncNotifier) + abgeleitete `kategorienProvider`/`locationsProvider`,
  Hook `onDatenGeaendert` für Widget-Updates (P06)
- **14 Unit-Tests grün** (`test/repositories/`), TDD: Tests vor Implementierung

**Was fehlt:** Anbindung der UI (P04/P05); Widget-Push im Hook (P06).

**Was gelernt:**
- json_serializable kopiert Default-Ausdrücke wörtlich ins `.g.dart` → Konstanten immer
  qualifiziert schreiben (`WhenOpenData.schemaVersion` statt `schemaVersion`)
- `File.rename` auf bestehendes Ziel wirft unter Windows → Fallback delete+rename (nur Tests;
  Android/POSIX ersetzt atomar)

## P03 — OpenStatus-Berechnung (2026-06-10)

**Was gebaut:**
- `OpenStatus`/`NextOpening` (mit `tageVoraus` 0..7), `WidgetData`/`WidgetEntry` (JSON-fähig für P06)
- `OpenStatusService` (zustandslos, Zeit immer als Parameter):
  `isOpenNow` (Blocklogik E9, von ≤ t < bis), `findNextOpening` (Wochengrenze, +1..+7),
  `naechsteAenderung` (E16: kleinste künftige Blockgrenze heute, sonst Mitternacht),
  `buildWidgetData` (offen/geschlossen, alphabetisch), `statusText` komplett über ARB
- **21 Unit-Tests grün**, inkl. Mehrblock-Tag mit 2 Pausen, Sa-23:59→Mo, "nie geöffnet"

**Was fehlt:** Verdrahtung in Liste (P05) und Widget (P06).

**Was gelernt:**
- `lookupAppLocalizations(Locale('de'))` macht ARB-Strings ohne BuildContext nutzbar —
  wichtig für Widget-Hintergrundprozess und Tests
- Grenzfall-Konvention dokumentiert: exakt `von` = offen, exakt `bis` = geschlossen
