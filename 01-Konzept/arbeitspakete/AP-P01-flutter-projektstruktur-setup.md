# Arbeitspaket

## AP-P01 — Flutter-Projektstruktur und Setup

| Feld | Wert |
|---|---|
| **Plan-ID** | P01 |
| **Spec-Referenz** | Rahmenbedingungen, Nicht-funktionale Anforderungen |
| **Komponente** | Projektfundament |
| **Agent** | Georg |
| **Geschätzte Größe** | ~300 LOC · ~45K Tokens |
| **Abhängig von** | — |
| **Übergabe an** | P02, P03, P04, P05 |

> ⚠️ **Aktualisiert 2026-06-10 (E15, E16):** Zusätzliche Dependencies vormerken: **`android_alarm_manager_plus`** (Grenz-Alarme) und **`workmanager`** (periodisches Netz) für die Widget-Aktualisierung (E16). Ordnerstruktur um `screens/kategorien_screen.dart`, einen `settings/`-Screen und `screens/quick_entry/kategorie_step.dart` ergänzen. Maßgeblich: [`../1.3-scope-entscheidungen.md`](../1.3-scope-entscheidungen.md).

---

## Ziel

Ein lauffähiges Flutter-Projekt für WhenOpen anlegen — mit vollständiger Ordnerstruktur, allen benötigten Dependencies, funktionierender Navigation und einem leeren Startscreen auf dem Android-Emulator.

---

## Eingaben

- `1.1-spezifikation.md` — Rahmenbedingungen (Flutter, Android API 26, Deutsch, go_router, Riverpod)
- `1.2-plan.md` — Projektstruktur (Abschnitt "Technische Details / Projektstruktur")

---

## Aufgaben

1. **Flutter-Projekt anlegen**
   - `flutter create when_open --org com.whenopen --platforms android`
   - Android `minSdkVersion` auf 26 setzen in `android/app/build.gradle`
   - App-Name in `AndroidManifest.xml` auf "WhenOpen" setzen

2. **Dependencies in `pubspec.yaml` eintragen**
   - `go_router` — Navigation mit Deep-Link-Support
   - `riverpod` + `flutter_riverpod` — State Management
   - `home_widget` — Android Widget Integration
   - `json_annotation` + `json_serializable` (dev) + `build_runner` (dev) — JSON-Serialisierung
   - `uuid` — UUID-Generierung für Location-IDs
   - `http` — HTTP-Client für OSM/Nominatim-Abfragen (P08b)
   - `intl` — Datums- und Zeitformatierung (i18n-Vorbereitung)

3. **Ordnerstruktur anlegen** (leere Dateien mit Platzhalter-Kommentar)
   ```
   lib/
   ├── main.dart
   ├── app.dart
   ├── models/
   ├── repositories/
   ├── services/
   ├── providers/
   ├── screens/
   │   └── quick_entry/
   └── widgets/
   test/
   ├── services/
   └── repositories/
   ```

4. **Grundnavigation einrichten** (go_router)
   - Route `/` → `HomeScreen` (Platzhalter: "WhenOpen – Liste kommt in P05")
   - Route `/detail/:id` → `DetailScreen` (Platzhalter)
   - Route `/quick-entry` → `QuickEntryScreen` (Platzhalter)
   - Deep-Link-Route `/open/:id` — für Widget-Tap (Platzhalter)

5. **Linting und Formatter konfigurieren**
   - `analysis_options.yaml` mit `flutter_lints` aktivieren
   - `dart format .` einmalig ausführen, Ergebnis committen

6. **i18n-Grundstruktur anlegen**
   - `lib/l10n/app_de.arb` mit einem Beispiel-String anlegen (`appTitle: "WhenOpen"`)
   - `flutter_localizations` in pubspec.yaml ergänzen
   - `MaterialApp` mit `localizationsDelegates` und `supportedLocales: [Locale('de')]` konfigurieren

7. **Smoke-Test**
   - App startet auf Android-Emulator (API 26+) ohne Fehler
   - Startscreen zeigt Platzhaltertext "WhenOpen"

---

## Lieferobjekt

- Vollständiges Flutter-Projektverzeichnis `when_open/`
- `pubspec.yaml` mit allen Dependencies
- `lib/app.dart` mit go_router-Konfiguration (4 Routen, Platzhalter-Screens)
- `lib/l10n/app_de.arb` mit `appTitle`
- `analysis_options.yaml`
- App läuft auf Android-Emulator

---

## Akzeptanzkriterien

- [ ] `flutter pub get` läuft ohne Fehler
- [ ] `flutter run` startet App auf Android-Emulator (API 26) ohne Fehler
- [ ] `minSdkVersion 26` in `build.gradle` gesetzt
- [ ] Alle 4 Routen in go_router definiert (auch wenn Screens Platzhalter sind)
- [ ] `flutter test` läuft ohne Fehler (noch keine Tests, aber Teststruktur vorhanden)
- [ ] `dart analyze` gibt keine Fehler aus

---

## Hinweise

- Kein eigener Code für Business-Logik oder Daten in diesem Paket — nur Struktur und Konfiguration
- `home_widget` benötigt zusätzliche Konfiguration in `android/` (AppGroupId) — das erfolgt in P06, hier nur als Dependency eintragen
- Der `quick_entry`-Unterordner in `screens/` ist für den mehrstufigen Dialog aus P04 vorbereitet
- Falls `json_serializable` Code-Generation beim Setup Probleme macht: vorerst weglassen, P02 richtet das ein
