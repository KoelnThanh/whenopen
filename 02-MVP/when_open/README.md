# WhenOpen

Android-App (Flutter) mit Home-Widget: speichert persönliche Öffnungszeiten **lokal** und
zeigt auf einen Blick, was gerade offen ist. Kein Backend, kein Login, JSON-Persistenz,
optionaler OSM/Nominatim-Import.

> Projektkontext, Plan und Inkrement-Protokoll: siehe `../../CLAUDE.md`,
> `../../01-Konzept/` und `../inkremente.md`.

## Schnellstart (Windows, bash-Shell)

Flutter liegt unter `C:\flutter\bin\flutter.bat` (nicht im PATH).

```bash
/c/flutter/bin/flutter.bat pub get
/c/flutter/bin/flutter.bat test       # Unit-Tests (Services, Repository, Parser, Validierung)
/c/flutter/bin/flutter.bat analyze
/c/flutter/bin/flutter.bat run        # auf laufendem Emulator Pixel_API35
```

## Architektur (Kurzform)

```
lib/
├── models/        Location, OpeningDay/TimeBlock (E9), Kategorie (E15), OpenStatus, NominatimResult
├── repositories/  LocationRepository — JSON laden/speichern (atomar), Backup bei Korruption
├── services/      OpenStatusService (jetzt offen? / nächste Öffnung / nächste Änderung E16),
│                  ValidationService, UrlService (P07), OpeningHoursParser + NominatimService (P08b)
├── providers/     Riverpod: appDataProvider + abgeleitete locations-/kategorienProvider
├── screens/       HomeScreen, DetailScreen, KategorienScreen, quick_entry/ (10-Schritt-Flow)
├── widget/        WidgetService — Push + AlarmManager-Planung (E16)
└── l10n/          Deutsche ARB-Strings

android/app/src/main/kotlin/.../  WhenOpenWidgetProvider/-Service/-ConfigActivity (RemoteViews)
android/app/src/main/res/layout/  when_open_widget*.xml
```

## Datenmodell

Schema 2.0: `{ version, kategorien[], eintraege[] }`. Ein `OpeningDay` hält eine Liste von
Zeitblöcken `{von, bis}` (E9; Pause = Lücke zwischen Blöcken). `Location.kategorie` verweist
per Kategorie-`id` (oder `null` = „Sonstige"). Beispiel: `../testdaten.json`.

## Tests

Unit-Tests unter `test/` (Repository, OpenStatusService, ValidationService,
OpeningHoursParser, Smoke-Widget-Test). Stand: 54 grün.
