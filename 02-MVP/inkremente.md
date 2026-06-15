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

## P04 — Schnelleintrag-Flow (2026-06-10, committet 4989d53)

**Was gebaut:**
- `QuickEntryScreen` als 10-Schritt-Flow (Name · Mo–So · Kategorie · Zusatzinfos),
  Fortschrittsbalken + Schrittanzeige; derselbe Screen dient via `editId` als Bearbeiten (P05)
- Mehrblock-Tageseditor `DayEntryStep` (E9): „＋ weiterer Zeitblock" statt Pausen-Toggle,
  Zeitpicker je Block; Vorschlagswert-Logik (`vorschlagFuer`: letzter gültiger Tag)
- `KategorieStep` (E15) mit Chips + „Neue Kategorie"-Dialog (Name/Farbe)
- `QuickEntryState` hält den Flow-Zustand, `toLocation`/`fromLocation` Mapping
- `ValidationService` (Pflichtfelder, von<bis, Block-Überlappung E9, https-URL P07) —
  Fehler springen zum betroffenen Schritt + SnackBar
- E11: weicher Hinweis ab 50 Einträgen, kein harter Block

**Was fehlt:** —

**Was gelernt:**
- Step-State außerhalb des Widgets (in `QuickEntryState`) halten, damit Zurück/Vor
  keine Eingaben verliert; `ValueKey(tag)` erzwingt frischen Block-Editor je Wochentag

## P05 — Hauptliste & Detailansicht (2026-06-10, committet 4989d53)

**Was gebaut:**
- `HomeScreen`: nach Kategorie gruppiert, **Bottom-Umschalter + PageView** (Google-Tasks-Stil,
  E10) — Wischen blättert zwischen „Alle Orte"/Kategorien/„Sonstige"; FAB legt im aktiven
  Filter vorbelegt an; Suche (AppBar-Icon); Timer auf `naechsteAenderung` (E16)
- `DetailScreen`: Wochenübersicht mit Mehrblock-Zeiten („·"-getrennt), „heute"-Hervorhebung,
  Kategorie-Pill, Adresse/Telefon als Quick-Actions (P07), Bearbeiten/Löschen
- `KategorienScreen` („Kategorien verwalten"): Umbenennen/Farbe/Zusammenführen/Löschen
- Löschen mit **Undo-SnackBar** (`undo_delete.dart`, E13); Schnell-Umhängen per Lang-Tippen
  (`kategorie_sheets.dart`); `location_list_tile.dart` mit Status-Punkt + Statustext
- Korrupte-Datei-Hinweis-Dialog (einmalig, aus `letzterLadefehler`)

**Was fehlt:** —

**Was gelernt:**
- PageView + Bottom-Sheet-Auswahl ersetzt Chip-Streifen sauber; aktive Seite = aktiver Filter
  hält FAB-Vorbelegung und Widget-Konzept (E14) konsistent

## P06 — Android Widget (2026-06-10/11)

**Was gebaut:**
- Nativer `WhenOpenWidgetProvider` (AppWidgetProvider) + `WhenOpenWidgetService`
  (RemoteViewsService) — Liste aus vorberechneten Dart-Daten (`home_widget`-SharedPrefs,
  Key `widget_daten`)
- E14: fester Kategorie-Filter pro Widget-Instanz, `WhenOpenWidgetConfigActivity` beim
  Platzieren; Kopf Kategorie links „▾" / Datum rechts, kein Schriftzug. „Alle Orte" →
  nach Kategorie gruppiert, fester Filter → flache Liste
- Zeilen-Tap: PendingIntent-Template + Fill-In `whenopen://app/open/<id>` → Detailansicht;
  Kopf-Tap → Konfig; Leerzustand-Tap → App
- E16-Verdrahtung (`WidgetService` in Dart): Push nach jeder Datenänderung + beim
  In-den-Hintergrund-Gehen (`AppLifecycleListener.onPause`), grenzgenauer
  `AndroidAlarmManager.oneShotAt` auf die nächste Block-Grenze (self-rescheduling, +5 s Puffer),
  WorkManager ~15 min als Sicherheitsnetz

**Was fehlt:** Widget-Konfig-Screen am Gerät noch nicht durchgespielt (Filter wird gesetzt,
visuelle Abnahme der Config-Activity offen).

**Was gelernt (E2E am Emulator, 2026-06-11):**
- **„Can't load widget"** kam von einem nackten `<View>` als Trennlinie — RemoteViews erlaubt
  nur eine View-Whitelist; `<FrameLayout>` ist inflatebar, `<View>` nicht. Fix behebt den Crash.
- `android_alarm_manager_plus` braucht **manuell deklarierte** Service/Receiver im Manifest —
  der Plugin-Manifest-Merge liefert sie auf Flutter 3.44 nicht.
- Widget-Push darf das Speichern nie scheitern lassen → `onDatenGeaendert`-Hook schluckt Fehler
  (WorkManager-Netz fängt verpasste Updates).
- Deep-Link `whenopen://app/open/<id>` über `am start` und über echten Widget-Zeilen-Tap
  verifiziert → öffnet korrekte Detailansicht.

## P07 — Google Maps URL-Integration (2026-06-10, committet 4989d53)

**Was gebaut:**
- `UrlService` (kein SDK/Key): `openGoogleMaps` (https-Validierung + Browser-Fallback),
  `openAddressInMaps` (`geo:`-Scheme → Maps-Web-Fallback), `openPhone` (`tel:`)
- Manifest `<queries>` für https/tel/geo; Integration in `DetailScreen` (Adresse/Telefon tippbar)

**Was fehlt:** —

**Was gelernt:**
- `LaunchMode.externalApplication` + `<queries>` nötig ab Android 11 (Package Visibility)

## P08b — OSM-Import-Assistent (2026-06-10, committet 4989d53)

**Was gebaut:**
- `NominatimService` (HTTP, User-Agent gesetzt) + `NominatimResult`-Modell
- `OpeningHoursParser`: OSM-`opening_hours` → 7×`OpeningDay` mit Mehrblock-Tagen (E9);
  deckt `Mo-Fr`, Tageslisten, `Su off`, `,`-Blöcke, Kleinschreibung/Leerraum ab;
  unbekannte Formate → `null` (Crash-frei, dann Handeingabe)
- Schnelleintrag-Einstieg „Ort aus dem Web übernehmen" → `OsmSearchStep` → `OsmConfirmStep`
  („Daten prüfen") → Felder vorbefüllen, Nutzer läuft normal durch und kann alles anpassen
- **8 Parser-Unit-Tests grün**

**Was fehlt:** `24/7`/`sunrise-sunset` werden bewusst nicht geparst (→ Handeingabe).

**Was gelernt (E2E am Emulator, 2026-06-11):**
- Live-Nominatim-Suche „Apotheke Viersen" liefert echte Treffer; realer
  `opening_hours`-String wird korrekt in Mehrblock-Tage geparst (Mo 08:30–13:00 · 14:30–18:30,
  Mi nur vormittags, So geschlossen) und in „Daten prüfen" angezeigt.

## Verifikation — End-to-End am Emulator (2026-06-11)

**Stand:** 54 Unit-Tests grün, `flutter analyze` sauber, Debug-APK baut/installiert auf
Pixel_API35 (Android 15). Mit kanonischen Testdaten (`02-MVP/testdaten.json`, 7 Orte/3 Kategorien)
durchgespielt und per Screenshot belegt:
- Hauptliste: Gruppierung + Status-Badges (offen grün „bis 12:00" / geschlossen grau „morgen ab …"), Seiten-Umschalter
- Detail (Bürgeramt): Mehrblock-Zeiten, „Do · heute"-Hervorhebung, Behörden-Pill, Adresse/Telefon
- Schnelleintrag: Schritt 1/10 + OSM-Einstieg
- OSM-Import: Suche → Trefferliste → „Daten prüfen" mit geparsten Mehrblock-Zeiten
- Widget: rendert (Filter „Behörden", „Do · 11. Juni"), Zeilen-Tap → Detail via Deep-Link

**Offen für P09 (Release):** App-Icon/Splash (noch Flutter-Default), Release-Signierung,
Play-Store-Listing + Privacy Policy, Widget-Config-Activity visuell abnehmen.

## P09 — Finalisierung & Play Store (2026-06-11)

**Was gebaut (Code-/Inhaltsseite, kontofrei):**
- **App-Icon** (Marke: Uhr 10:10 + grüner Haken auf Teal #2F6F6B): Quell-PNGs per Pillow
  erzeugt (`tool/gen_icon.py` → `assets/icon/icon.png` + `icon_foreground.png`),
  `flutter_launcher_icons` generiert alle mipmaps + Adaptive Icon (minSdk 26).
  Ersetzt Flutter-Default — am Emulator verifiziert.
- **Splash** via `flutter_native_splash`: dunkler Brand-BG #0F1115 + zentriertes Icon,
  inkl. Android-12-Styles (`values-v31`, `windowSplashScreenAnimatedIcon`).
- **Strings**: kein hartkodierter Anzeigetext (alles über ARB), `flutter analyze` sauber,
  App-Label „WhenOpen".
- **Release-Signierung**: Keystore `android/whenopen-release.jks` (Upload-Key, RSA 2048,
  10000 Tage) + `android/key.properties`; `build.gradle.kts` lädt sie und signiert den
  Release-Build (Fallback Debug-Key, wenn key.properties fehlt). Beide Secrets gitignored.
- **Release-AAB**: `flutter build appbundle --release` → `app-release.aab` **52,1 MB**
  (< 150 MB), mit `jarsigner -verify` bestätigt: signiert mit **CN=WhenOpen** (nicht Debug).
- **Privacy Policy** `docs/privacy-policy.md` (keine Datensammlung, lokal; OSM-Suche sendet
  nur den Suchbegriff an Nominatim) — bereit für GitHub Pages.
- **Play-Store-Listing** `04-Release/play-store-listing.md` (Kurz-/Langbeschreibung DE,
  Kategorie Produktivität, Screenshot-/Einreichungs-Hinweise).

**Was fehlt (kontoabhängig, durch Auftraggeber):**
- Google-Play-Developer-Konto ($25) — Voraussetzung für Upload.
- GitHub Pages aktivieren → Privacy-Policy-URL ins Listing eintragen.
- AAB hochladen (Internal Testing), Store-Screenshots aufnehmen, Repo public + `git tag v1.0.0`.

**Was gelernt:**
- Adaptive-Icon-Vordergrund muss in der Safe-Zone (~innere 66 %) liegen → `icon_foreground.png`
  bewusst kleiner gezeichnet als das volle `icon.png`.
- `key.properties`/`*.jks` vor dem ersten Commit gegen `.gitignore` geprüft (`git check-ignore`)
  — Keystore-Verlust = keine App-Updates mehr (bei Play App Signing nur Upload-Key, rücksetzbar).
- `flutter_native_splash` legt für Android 12+ eigene `values-v31`-Styles an; der alte
  `windowBackground`-Splash gilt nur < API 31.

## P09-Fix — Release-Crash (R8/WorkManager) (2026-06-11)

**Symptom (auf echtem Handy, Release-APK):** App öffnet und schließt sofort; Widget lässt
sich nicht hinzufügen („erscheint nichts"). Im Debug/Emulator trat es nie auf.

**Diagnose:** Release-APK auf den Emulator gespielt (Release-Crash ist build-, nicht
gerätespezifisch → ohne Handy reproduzierbar), `logcat` mitgeschnitten:
```
FATAL EXCEPTION: main — Unable to get provider androidx.startup.InitializationProvider:
  java.lang.NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init> []
  at androidx.work.WorkManagerInitializer...
```
R8 (in AGP 8 standardmäßig „full mode") hatte die per Reflexion instanziierte
`WorkDatabase_Impl` von WorkManager/Room entfernt/umbenannt. Da WorkManager über
`androidx.startup`-ContentProvider **vor** jeder Activity initialisiert, stirbt der ganze
App-Prozess beim Start — egal ob App-Start oder Widget-Konfiguration (gleicher Prozess),
daher beide Symptome.

**Fix:** Minification + Resource-Shrinking für den Release-Build abgeschaltet
(`build.gradle.kts` → `isMinifyEnabled = false`, `isShrinkResources = false`). Für dieses
kleine MVP kostet R8 mehr (Reflexions-Bugs bei WorkManager/home_widget/alarm_manager) als es
an Größe spart. APK 53,2 → 57,9 MB.

**Verifiziert (Release-APK am Emulator):** App startet ohne FATAL, Schnelleintrag („+" →
„Schritt 1 von 10"), Widget-Config-Activity startet crashfrei. Reparierte APK an Auftraggeber.

**Was gelernt:**
- **Immer einen Release-Build auf Gerät/Emulator testen, nicht nur Debug** — R8-Reflexions-
  Crashes sind release-only und im Debug unsichtbar.
- Release-Crashes lassen sich ohne das Zielgerät reproduzieren: dieselbe Release-APK auf den
  Emulator, `adb logcat` → echte Exception statt Raten.
- Reines `flutter analyze`/Unit-Tests fangen R8-Stripping nicht — das ist ein Build-/
  Laufzeitthema. Wenn R8 später zurück soll: Keep-Regeln für WorkManager/Room/home_widget/
  alarm_manager + Gerätetest, oder `android.enableR8.fullMode=false`.

## P09-Fix 2 — Untere Leiste auf 3-Tasten-Navigation (2026-06-11)

**Symptom (Samsung-Handy, 3-Tasten-Navigation):** Untere Leiste gequetscht — „Alle Orte"
nur als Schlitz, „+"-Button plattgedrückt, alles an die Navigationsleiste gepresst
(„Screen nicht optimal ausgenutzt"). Auf dem Emulator mit **Gesten**-Navigation (kleiner
Inset) fiel es nicht auf.

**Ursache:** In `_BottomBar` lag die `SafeArea(top:false)` **innerhalb** des
`Container(height: 64)`. Der Inset für die System-Navigationsleiste (bei 3-Tasten ~48 px)
wurde so von den festen 64 px abgezogen → nur ~16 px für den 50-px-Button.

**Fix (`home_screen.dart`):** Reihenfolge gedreht — `Container(bg) > SafeArea(top:false) >
Container(height:64) > Row`. Der Navi-Abstand kommt jetzt additiv **unter** die 64-px-Leiste,
die Hintergrundfarbe füllt den Inset-Streifen. Zusätzlich `_Leerzustand` aufgewertet
(Uhr-Icon + klarere Typografie statt nur Text).

**Reproduziert & verifiziert am Emulator:** auf **3-Tasten-Navigation** umgestellt
(`adb shell cmd overlay enable …navbar.threebutton`) → Quetschung sichtbar; nach Fix sitzen
„Alle Orte" + „+" in voller Größe sauber über der Navigationsleiste.

**Was gelernt:**
- Bei `Scaffold.bottomNavigationBar` die `SafeArea` **um** die fixe Höhe legen, nie hinein —
  sonst frisst der System-Inset die Leiste.
- Layout immer auch mit **3-Tasten-Navigation** prüfen (größerer unterer Inset als Gesten-Navi)
  — `adb shell cmd overlay enable com.android.internal.systemui.navbar.threebutton` macht das
  am Emulator testbar.

## P10 — Redesign v0.3 (Indigo, Hell/Dunkel) — Schritt 1: Marke + Home + Icon (2026-06-11)

Auf Nutzerwunsch nach P09: UI-Facelift (neue Markenfarbe **Indigo**, Hell+Dunkel folgt System,
Hero-Header statt nacktem AppBar-Balken) + **Logo B (PinTime)** als Icon + **JSON-Backup**.
Umsetzung in verifizierten Teilschritten, jeder Commit lauffähig. Design-Referenz: v0.3-Sektion
in `01-Konzept/mockups/whenopen-mockups.html`.

**Was gebaut (Schritt 1):**
- **Theme-Fundament** (`theme/app_theme.dart`): Markenfarbe Teal→**Indigo #6366F1**;
  `AppPalette` als `ThemeExtension` mit Dunkel- *und* Hell-Instanz (neutrale Flächen-/Textfarben),
  Zugriff über `context.col`. `buildDarkTheme()`/`buildLightTheme()` vorhanden (App nutzt aktuell
  Dunkel; System-Umschaltung folgt in Schritt 3). Flache AppBar in Flächenfarbe statt farbigem Balken.
- **Home-Redesign** (`screens/home_screen.dart`): **Hero-Header** mit Pin-Markenzeichen +
  Wortmarke (Indigo-Akzent) + Datum (`DateFormat('EEEE, d. MMMM','de')`) + **Status-Übersicht
  „X jetzt offen / Y geschlossen"**. Such-Lupe + ⋮-Menü (Kategorien verwalten) im Header.
  Gruppenköpfe mit Kategorie-Farbpunkt. Bottom-Umschalter neu gestylt (Indigo-FAB-Verlauf,
  Pillen-Seitenindikator).
- **Listenzeile** (`widgets/location_list_tile.dart`): schlanke Karte mit **Kategorie-Akzentstreifen**
  links + **farbiger Uhrzeit** (grün offen / grau zu) — kein Punkt, kein Kasten (Nutzer-Feedback).
- **Logo-B-Icon**: `tool/gen_icon.py` neu → Indigo-Verlauf + weißer Karten-Pin mit Uhr;
  `flutter_launcher_icons` (adaptive, `adaptive_icon_background #4F46E5`) + `flutter_native_splash`
  (BG #0E1116) neu generiert.
- **i18n**: `homeOffenZahl`/`homeZuZahl` in ARB; `initializeDateFormatting('de')` in `main.dart`.

**Verifiziert:** `flutter analyze` sauber, **54 Unit-Tests grün**, Debug-APK am Emulator
(Pixel_API35) mit Testdaten — Hero-Header, „6 offen/1 geschlossen", Akzentstreifen + farbige
Uhrzeiten, Indigo-FAB per Screenshot bestätigt. Neues App-Icon (Pin+Uhr) sichtbar.

**Was fehlt (Schritt 2/3):** Backup/Wiederherstellen (JSON-Export/Import) · Widget-Feinschliff
(Punkt/Kasten raus) · Light-Mode flächendeckend (restliche ~70 Farbstellen der Nebenscreens auf
`context.col` ziehen) + Hell-Modus am Emulator abnehmen, dann `themeMode: system` aktivieren.

**Was gelernt:**
- **Signatur-Konflikt live reproduziert:** Release-Build lag auf dem Emulator, Debug-Install →
  `INSTALL_FAILED_UPDATE_INCOMPATIBLE` + `run-as: package not debuggable`. Bestätigt die Diagnose
  zum „Datenverlust beim Aktualisieren": gleiche Signatur = In-Place-Update, sonst Deinstallation nötig.
- `ThemeExtension` + `context.col`-Getter ist der saubere Weg für Hell/Dunkel; markenfeste Farben
  (Primär, Status, Kategorie-Swatches) bleiben als `AppColors`-Konstanten, nur Neutrale kippen.
- `DateFormat` mit Nicht-`en`-Locale braucht `initializeDateFormatting('de')` in `main()`.

## P10 — Schritt 2: JSON-Backup/Wiederherstellen + Feinschliff (2026-06-11)

**Was gebaut:**
- **Repository** (`location_repository.dart`): `exportKopie()` schreibt eine datierte, teilbare
  Kopie (`whenopen-sicherung-<datum>.json`) ins Temp-Verzeichnis; `importJson(String)` validiert
  zuerst (Wurzel mit `version` + Liste `eintraege`, sonst `FormatException`), **sichert die aktuelle
  Datei** (`whenopen_backup_<ts>.json`) und schreibt erst dann — Bestandsdaten bleiben bei Fehler intakt.
- **Provider**: `exportKopie()` + `importJson()` (lädt danach Zustand + Widget neu).
- **UI** (`home_screen.dart`): ⋮-Menü erweitert → „Kategorien verwalten / Daten sichern / Daten
  wiederherstellen". „Sichern" öffnet den System-Teilen-Dialog (Drive/E-Mail/Dateien).
  „Wiederherstellen" = Einfügen-Dialog (JSON-Inhalt der Sicherung einfügen → bestätigen → Import).
- **Feinschliff**: Akzentstreifen der Listenzeile kleiner + eingerückt (läuft nicht mehr über die
  Kartenecken); **Logo B überarbeitet** — Uhr liest sich nicht mehr nur als Punkt: klares
  Indigo-Zifferblatt (Ring + 10:10-Zeiger) mit **grünem „offen"-Mittelpunkt** auf weißer Pin-Fläche.

**Verifiziert:** `analyze` sauber, **58 Tests grün** (4 neue Import-/Backup-Tests), am Emulator:
⋮-Menü mit 3 Einträgen, „Daten sichern" → Teilen-Dialog mit `whenopen-sicherung-2026-06-11.json`
(Quick Share/Drive/Gmail) bestätigt; neues Launcher-Icon (Pin+Uhr) im App-Drawer sichtbar;
eingerückte Akzentstreifen.

**Verworfen:** `file_picker` für den Datei-Dialog beim Import — Versionskonflikt
(`file_picker@8.1.2` ist gegen android-34 kompiliert, seine Transitive
`flutter_plugin_android_lifecycle` verlangt compileSdk 36 von allen Konsumenten →
`:file_picker:checkDebugAarMetadata` schlägt fehl). Statt die Build-Kette (R8-empfindlich) zu
destabilisieren: **abhängigkeitsfreier Einfüge-Dialog**. Datei-Auswahl ggf. später, wenn eine
kompatible Plugin-Kombination steht.

**Was fehlt (Schritt 3):** Light-Mode flächendeckend (restliche ~70 `AppColors.*`-Stellen der
Nebenscreens auf `context.col`) · Hell/Dunkel-Umschalter im ⋮-Menü · Widget-Feinschliff (Punkt/Kasten
raus) · dann Hell-Modus am Emulator abnehmen.

## P11 — Such-Verbesserung (Option A/B) + Umkreissuche per Heimatadresse (2026-06-11)

Auf Nutzerwunsch nach den Doku-/Bewertungs-Dateien (`01-Konzept/1.4-architektur.md`,
`1.5-suche-gps-evaluation.md`): Internetsuche verbessern **und** „alle umliegenden Orte finden".
Bewusst **ohne GPS** — die Heimatadresse wird **einmalig per Nominatim geocodet und lokal
gespeichert**, daher **keine Standort-Berechtigung** und kein Bruch des „alles bleibt lokal"-
Versprechens. Grundlage: Stufenplan A/B/C aus `1.5`.

**Was gebaut:**
- **Schema 2.1** (`models/app_einstellungen.dart`): neues `AppEinstellungen` (heimatAdresse,
  heimatLat/Lon, umkreisMeter=1500) als Feld in `WhenOpenData`. Alte 2.0-Dateien laden mit Default
  (rückwärtskompatibel, per Test belegt). `LocationRepository.get/setEinstellungen`,
  `AppDataNotifier.setEinstellungen` + `einstellungenProvider`.
- **Option A — Nominatim-Tuning** (`nominatim_service.dart`): `countrycodes=de`,
  `accept-language=de`, `layer=poi,address`, `limit` 5→8; Debounce 500→800 ms (Policy-näher).
- **Option B — Overpass-Nachlookup** (`services/overpass_service.dart`, neu): beim Auswählen eines
  Nominatim-Treffers ohne Öffnungszeiten werden dessen OSM-Tags per **1 Overpass-Request**
  (`<typ>(<id>);out tags;`) nachgeladen → deutlich höhere Trefferquote für `opening_hours`.
  `NominatimResult` um `osmType/osmId/lat/lon` + `copyWith` + `fromOverpassElement` erweitert.
- **Umkreissuche „Orte in der Nähe"** (`overpass_service.findeUmkreis` +
  `screens/quick_entry/umkreis_search_step.dart`): `nwr[opening_hours](around:R,lat,lon);out center
  tags;` um die Heimatkoordinaten → Liste der POIs mit Öffnungszeiten → derselbe „Daten
  prüfen"-Flow (`OsmConfirmStep`) wie der Web-Import. Zweiter Einstieg in `NameStep`
  („Orte in der Nähe"); ohne Heimatadresse → Hinweis-SnackBar mit Sprung in die Einstellungen.
- **Einstellungen-Screen** (`screens/einstellungen_screen.dart` + Route `/einstellungen` +
  ⋮-Menüeintrag): Heimatadresse **suchen** (Nominatim) → wählen → Koordinaten lokal speichern;
  **Umkreis-Regler** 250–5000 m; OSM/ODbL-Attribution.
- **i18n**: ~25 neue ARB-Strings; geteilter `widgets/umkreis_format.dart` („750 m"/„1,5 km").

**Verifiziert:** `flutter analyze` **sauber**, **71 Unit-Tests grün** (+13: 3 Einstellungs-/Schema-
2.1-Roundtrip & 2.0-Rückwärtskompatibilität, 10 Overpass — Query-Bau, Element-Parsing,
Mock-HTTP). **End-to-End am Emulator (Pixel_API35, Debug-APK)** mit Heimatadresse Viersen
(Seed Schema 2.1): App lädt 2.1 ohne Crash → ⋮-Menü zeigt „Einstellungen" → Einstellungen-Screen
mit Heimat-Karte + Suchradius „2 km" + ODbL-Attribution → Schnelleintrag zeigt zweiten Einstieg
„Orte in der Nähe" → **Live-Overpass** liefert echte Treffer im 2-km-Umkreis (Adler-/Aesculap-
Apotheke, ALDI, Stadtbibliothek …, alphabetisch, Uhr-Icon) → „Daten prüfen" mit Name, Adresse,
Telefon und **korrekt geparsten Mehrblock-Zeiten** (Mo–Fr 08:30–18:30 · Sa 09:00–13:00 · So zu).
Alles per Screenshot belegt.

**Bewusst kein GPS:** Die Adress-Lösung erfüllt den Nutzerwunsch ohne `geolocator`/
`ACCESS_*_LOCATION` — keine Manifest-Änderung, keine Play-Data-Safety-Folgen. GPS-„aktueller
Standort" bleibt als optionale v2-Erweiterung am selben `findeUmkreis`-Pfad andockbar.

**Was gelernt:**
- json_serializable kopiert Default-Ausdrücke wörtlich ins `.g.dart` → `AppEinstellungen.standardUmkreis`
  **qualifiziert** schreiben (sonst `undefined_identifier` in `app_einstellungen.g.dart`) —
  bestätigt das P02-Learning.
- Nominatim ist Geocoder (Text→Ort), Overpass ist die POI-Datenbankabfrage (`around:`). Beide teilen
  sich das `NominatimResult`-Modell; `fromOverpassElement` nutzt `out center` für Flächen (way/relation).

## P12 — Sichern/Teilen/Wiederherstellen überarbeitet (2026-06-12)

Nutzerwunsch: Die JSON-Sicherung war unhandlich — „Sichern" öffnete sofort den Teilen-Dialog
(Datei ohne festen Ort), und „Wiederherstellen" verlangte, den **kompletten JSON-Inhalt als Text
einzufügen** (Datei öffnen → alles kopieren → einfügen). Ziel: **kein Text-Kopieren mehr**, fester
**sichtbarer** Speicherort, Sichern und Teilen getrennt.

**Was gebaut — drei getrennte ⋮-Menü-Aktionen statt einer:**
- **Sichern** schreibt in den **im Dateimanager sichtbaren** Ordner `Download/WhenOpen` und
  **überschreibt** `whenopen-sicherung.json` (immer genau eine aktuelle Datei) — kein Teilen-Dialog,
  nur Snackbar „Gesichert in Download/WhenOpen".
- **Teilen** (neu, separat) öffnet den Android-Teilen-Dialog mit einer **datierten** Kopie
  (WhatsApp/Drive/Gmail) zum Weitergeben.
- **Wiederherstellen** öffnet ein Auswahl-Sheet: **„Letzte Sicherung laden"** (neueste Datei aus
  `Download/WhenOpen`) **oder „Datei wählen…"** (System-Dateibrowser — auch für **empfangene**
  Sicherungen). Danach **Vorschau-Dialog** („Diese Sicherung enthält X Orte und Y Kategorien",
  „Deine jetzigen N Orte werden vorher gesichert") → bestätigen → Import.

**Technik:**
- **Nativer Speicher-Kanal** `com.whenopen/backup` (`BackupStorage.kt` + `MainActivity.kt`):
  MediaStore-Downloads ab Android 10 (ohne Berechtigung; Overwrite = Eintrag per
  `RELATIVE_PATH`+`DISPLAY_NAME` suchen → `openOutputStream(uri,"wt")`); Legacy-Pfad <API 29 mit
  `WRITE/READ_EXTERNAL_STORAGE` (`maxSdkVersion=28`). „Datei wählen" via `ACTION_OPEN_DOCUMENT` +
  `onActivityResult` (liest content://-URI → `{name, inhalt}`). Dart-Brücke:
  `services/downloads_backup_service.dart` + `downloadsBackupServiceProvider`.
- **Repository**: Validierung als `pruefeSicherung()` herausgezogen (prüft **ohne zu speichern**, für
  die Vorschau); `exportInhalt()` (pretty JSON, von Sichern + Teilen genutzt); `importJson` baut darauf.
- **Provider**: `sichern()`, `letzteSicherungInhalt()`, `pruefeSicherung()`.
- **i18n**: Menü „Sichern/Teilen/Wiederherstellen"; neue Strings inkl. ICU-Plurale (Orte/Kategorien);
  Copy-Paste-Texte (`wiederherstellenText/Hint`) entfernt.

**Verifiziert:** `analyze` sauber, **78 Unit-Tests grün** (+7: 3 Export/Vorschau im Repo, 4 Service-
Kanal). **End-to-End am Emulator (Pixel_API35, Debug-APK, 7 Test-Orte)**, je per Screenshot:
Sichern → `Download/WhenOpen/whenopen-sicherung.json` (11,67 kB) angelegt, **2× Sichern = weiterhin
genau 1 Datei** (Overwrite), Snackbar; Wiederherstellen-Sheet mit beiden Optionen; „Letzte Sicherung
laden" → Vorschau „7 Orte / 3 Kategorien" → Import → **Pre-Import-Backup** im App-Ordner +
„Daten wiederhergestellt"; „Datei wählen" → DocumentsUI → `Downloads › WhenOpen` → Datei → zurück in
die App mit Quelle „whenopen-sicherung.json" → Import; Teilen → Android-Chooser „Sharing 1 file:
whenopen-sicherung-2026-06-12.json".

**Verworfen:** `file_picker` (Paket). Version 11.0.2 ist mit Flutter 3.44s **„Built-in Kotlin"**
inkompatibel — das Kotlin-Modul landet nicht im Classpath, der `GeneratedPluginRegistrant` findet
`FilePickerPlugin` nicht, der Build bricht bei `compileDebugJavaWithJavac`. Schon die P10-Session war an
file_picker gescheitert (damals compileSdk-Konflikt). Lösung: **„Datei wählen" nativ** über
`ACTION_OPEN_DOCUMENT` — keine Dependency, gleicher Kanal wie MediaStore.

**Scoped-Storage-Grenze (bewusst):** „Letzte Sicherung laden" via MediaStore sieht **nur von WhenOpen
selbst angelegte** Dateien. Eine über WhatsApp empfangene, im Ordner abgelegte Sicherung wird daher über
**„Datei wählen…"** geladen (ein Tipp, kein Kopieren). Der „Öffnen mit WhenOpen"-Weg direkt aus dem Chat
(Intent-Filter + receive-intent) bleibt als optionale Erweiterung offen.

**Was gelernt:**
- Flutter 3.44 „Built-in Kotlin": Plugins, die KGP selbst anwenden, können brechen — Symptom ist ein
  **fehlendes Plugin-Symbol im `GeneratedPluginRegistrant`**, nicht ein Kotlin-Compilerfehler. Ein eigener
  MethodChannel ist robuster als ein fragiles Paket. (Die KGP-**Warnung** für die übrigen Plugins bleibt
  — nur ein Hinweis, kein Fehler.)
- MediaStore-Overwrite braucht die Suche nach dem bestehenden Eintrag; sonst legt MediaStore
  „… (1).json" an statt zu überschreiben.

## P13 — „Über WhenOpen": Persönliche Vorstellung + Unterstützen (2026-06-12)

**Warum:** Bei einer lokalen, trackingfreien App ist ein ehrlicher „Über mich"-Teil ein
**Vertrauenssignal** (beantwortet „warum kostenlos? wo ist der Haken?"). Spenden sind das
einzige Monetarisierungsmodell, das die Privacy-Haltung nicht verrät — bewusst dezent, ohne
Bettel-Charakter, ohne Gegenleistung (sonst Google-Play-Billing-Pflicht).

**Was gebaut:**
- Neuer Screen `screens/ueber_screen.dart` (Route `/ueber`, erreichbar über neuen
  ⋮-Menüeintrag „Über WhenOpen" im Home-Header): Markenkopf (Pin + Wortmarke + Tagline),
  „Über mich"-Karte (Gruß + 4 Absätze in Thanhs eigener Fassung; Privacy-Aussage „kein Konto,
  keine Cloud, kein Tracking" steht in der Prosa, daher keine separate Schloss-Zeile),
  Unterstützen-Bereich, Footer mit Version + OSM-Attribution.
- **Spendenlink als eine Konstante** `kSpendenUrl` ganz oben im File. **Leer ('') = der
  Unterstützen-Button blendet sich automatisch aus** → es wird nie ein toter Link
  veröffentlicht. **Gesetzt auf `https://paypal.me/koelnthanh`** (2026-06-12) → Button live.
- Spenden-Button: `FilledButton.icon` (Herz + „Spendier mir einen Kaffee ☕"), öffnet den
  Link via `url_launcher` (`LaunchMode.externalApplication`) — gleicher Pfad wie die
  Google-Maps-Links (P07), Manifest-`<queries>` für https greift bereits.
- Persönliche Prosa (`kUeberGruss`, `kUeberAbsaetze`) **inline statt in l10n** — bewusst,
  damit der Text ohne ARB-Escaping frei editierbar bleibt. UI-Chrome (Menü, Titel, Button,
  Hinweis, Version) läuft über l10n (`menueUeber`, `ueberTitel`, `ueberTagline`,
  `ueberUnterstuetzenTitel/Hinweis`, `ueberKaffeeButton`, `ueberLinkFehler`, `ueberVersion`).
  App-Version als `kAppVersion`-Konstante (synchron zu `pubspec.yaml`).

**Verifiziert:** `analyze` sauber, **78 Unit-Tests grün** (unverändert). **End-to-End am
Emulator (Pixel_API35, Debug-APK)** per Screenshot: Über-Screen via Deep-Link
`whenopen://app/ueber` rendert korrekt (Markenkopf, Text, Schloss-Vertrauenszeile, Version
1.0.0, OSM-Attribution). Mit temporär gesetztem Demo-Link: Unterstützen-Bereich + Voll-Button
sichtbar; **Tap öffnet den externen Browser** mit `https://paypal.me/koelnthanh` (im Logcat als
`START act=VIEW dat=https://paypal.me/... cmp=com.android.chrome` von der App-uid bestätigt).

**Was gelernt:**
- Google Play: externer Spendenlink **ohne** versprochene Gegenleistung ist zulässig; Play
  Billing (15–30 % Cut, für Privatperson gesperrt) wäre nur bei „Feature gegen Spende" Pflicht.
  → Spenden nie an Funktionen koppeln. Vor Store-Submit aktuelle Donation-Policy gegenchecken.

## P14 — Erstnutzer-Tutorial / Onboarding (2026-06-12)

**Warum:** Bei leerer App (kein Datenfile) war der Einstieg ein kalter Start — der Nutzer
sah nur „Tippe auf +". Das Tutorial erklärt die Grundpfeiler (Kategorien, Daten, einmalige
Adresse statt GPS, E-Mail, optional Spenden) und führt am Ende direkt in den ersten Eintrag.

**Was gebaut:**
- **Persistenz-Flag:** `AppEinstellungen.tutorialStatus` (Enum `offen`/`abgelehnt`/
  `abgeschlossen`, Default `offen`). `@JsonKey(unknownEnumValue: offen)` → alte Dateien ohne
  Feld **und** unbekannte Werte laden migrationssicher als `offen`. `build_runner` regeneriert
  `app_einstellungen.g.dart`. Im selben Zug **Default-Suchradius 1500 → 1000 m** (1 km) — wirkt
  nur für Neuinstallationen/Default, Bestandswerte bleiben (keine Migration, bewusst).
- **Erstnutzungs-Prädikat:** `zeigeOnboardingProvider` (leere Eintragsliste **und**
  `tutorialStatus == offen`) + `AppDataNotifier.setTutorialStatus(...)` (kapselt `copyWith`).
- **Home-Gate:** `_zeigeOnboardingFallsNoetig()` läuft im selben Post-Frame-Callback **nach**
  `_zeigeLadefehlerFallsNoetig()` (Ladefehler hat Vorrang → bei beschädigten Daten kein
  Tutorial), abgesichert per bool-Guard `_onboardingGeprueft`. Dialog `barrierDismissible:false`
  mit „Nein, danke" (→ `abgelehnt`, dauerhaft) / „Tour starten" (→ `/onboarding`).
- **OnboardingScreen** (`screens/onboarding_screen.dart`, Route `/onboarding`): `PageView` mit
  7 Karten (Willkommen · Kategorien · Daten · Adresse · E-Mail · Spenden[nur wenn `kSpendenUrl`
  gesetzt] · Fertig), Seiten-Punkte, „Überspringen", Abschluss-CTA „Ersten Ort anlegen".
  Beenden setzt `abgeschlossen` und springt per `pushReplacement` in den geführten Quick-Entry
  bzw. (Überspringen) zurück zum Home.
- **`HeimatAdresseEingabe`-Widget** aus `einstellungen_screen` extrahiert (`widgets/`) — Nominatim-
  Geocoding, **kein GPS** — und in Einstellungen **und** der Adress-Karte wiederverwendet (keine
  Doppel-Logik). Adress-Auswahl im Onboarding speichert sofort → schaltet „Orte in der Nähe" frei.
- **E-Mail (neu):** `UrlService.openEmail(mailto:)` + Kontakt-Block im `ueber_screen`
  (`kKontaktEmail`) + E-Mail-Karte im Onboarding. Spenden-Karte nutzt `kSpendenUrl` wieder.
- **Geführter Quick-Entry:** `QuickEntryScreen(tutorial:)` (Route reicht `?tutorial=1`) blendet in
  Schritt 0 einen Hinweis-Banner zu „Orte in der Nähe" ein.
- **l10n:** ~30 neue Strings (`tutorialDialog*`, `onboarding*`, `ueberKontakt*`,
  `tutorialQeHinweis`), `gen-l10n` neu generiert.

**Bewusst NICHT gebaut:** keine Apotheken-Filterung — auf Wunsch sucht die geführte Aufgabe
**einen beliebigen** lokalen Ort (OverpassService unangetastet). „2 km → 1 km" war faktisch
1,5 km → 1 km (es gab nie einen 2000er-Default).

**Verifiziert:** `analyze` sauber, **90 Unit-Tests grün** (12 neu: 7× Modell-Serialisierung/
Migration/Radius, 5× `zeigeOnboardingProvider` über echte Repo-/Provider-Verdrahtung inkl.
Persistenz nach Neuladen). **End-to-End am Emulator (Pixel_API35, Debug-APK)** per Screenshot:
`pm clear` → Erstnutzer-Dialog „Kurze Einführung?" → „Tour starten" → Karten (Willkommen…) →
Adress-Karte mit **wortgenauem GPS-Hinweis** + Suchfeld → „Los geht's!" → „Ersten Ort anlegen"
öffnet Quick-Entry **mit Tipp-Banner**; **Kaltstart nach Abschluss zeigt KEINEN Dialog mehr**
(Home leer).

**Was gelernt:**
- **Reset-Falle:** `EinstellungenScreen._speichern()` baute früher ein **frisches**
  `AppEinstellungen(...)`. Mit dem neuen Default-Feld hätte jedes Settings-Speichern
  `tutorialStatus` auf `offen` zurückgesetzt → Tutorial-Wiedergänger. Lösung: `copyWith` auf den
  **aktuellen** Einstellungen. Lehre: neue Default-Felder + „Objekt frisch bauen"-Saves = Bug.
- Erstnutzung an einem **persistenten Flag** festmachen, nicht nur an leeren Daten — sonst poppt
  das Tutorial nach „alle Orte gelöscht" oder leerer Wiederherstellung erneut auf.
- json_serializable-Enums brauchen `unknownEnumValue` für Vor-/Rückwärtskompatibilität; ohne
  `build_runner`-Lauf driften Modell und `.g.dart`.
- Emulator-Quirk: `PageController.nextPage` wird **während** der 250-ms-Animation ignoriert →
  schnelle `input tap`-Folgen werden verschluckt. `uiautomator dump` zwischen den Taps als
  zuverlässige Verzögerung (statt im Bash-Tool gesperrtem `sleep`).

## P15 — UX-Feinschliff: Eingabe-Einstieg, Widget-Hinweis, Spenden-Timing, Logo (2026-06-12)

**Warum (4 Nutzerpunkte):** (1) „+" öffnete sofort die Tastatur, obwohl der Standardweg lokal
(OSM/Umkreis) sein soll. (2) Tutorial erklärte alles außer der Kerngeschichte — dem **Widget**.
(3) E-Mail-/Kaffee-Bitte kam **zu früh** (im Tutorial, bevor die App lief). (4) Das In-App-Logo
war ein nackter `Icons.location_on` (Pin **ohne** Uhr → wirkte wie ein Ordner-Icon), obwohl das
App-Icon ein Pin **mit** Uhr ist.

**Was gebaut:**
- **Punkt 1 — Methodenauswahl statt Auto-Keyboard** (`screens/quick_entry/start_auswahl_step.dart`,
  neu): Beim Anlegen erscheint zuerst eine Auswahl — **„Ort suchen" (OSM)** und **„Orte in der
  Nähe" (Umkreis)** prominent (Indigo-Kacheln), **„Manuell eingeben"** als dezente dritte Option
  unter einem „oder"-Trenner. `QuickEntryScreen`: neue Flags `_zeigeStartAuswahl` (Neuanlage
  startet darin; Bearbeiten überspringt sie) und `_nameAutofokus` (Tastatur **nur** bei „Manuell").
  Nach Import verlässt `_wendeUebernahmeAn` die Auswahl und zeigt das vorbefüllte Namensfeld
  **ohne** Tastatur; abgebrochener Import bleibt in der Auswahl. `_zurueck` aus dem Namensfeld
  führt (Neuanlage) zurück zur Auswahl. `NameStep` ist jetzt reines Namensfeld (`autofocus`-Param),
  die OSM-/Umkreis-Buttons sind in die Auswahl gewandert.
- **Punkt 2 — Widget-Seite im Tutorial** (`onboarding_screen.dart`): neue Karte „Das Herzstück:
  das Widget" als **2. Seite** (direkt nach Willkommen) mit nummerierter Schritt-für-Schritt-
  Anleitung (`_WidgetSchritte`): lange auf Startbildschirm → „Widgets" → WhenOpen ziehen.
  Fertig-Seite erinnert zusätzlich ans Widget.
- **Punkt 3 — Spenden/Feedback erst nach Bewährung** (`home_screen.dart` +
  `app_einstellungen.dart`): E-Mail- und Spenden-Seite aus dem Tutorial **entfernt**. Stattdessen
  einmaliger Dialog „Gefällt dir WhenOpen?" (Kaffee primär, Feedback sekundär, „Später"), der
  **erst ab dem 5. gespeicherten Ort** über `_pruefeStartDialoge → _zeigeSpendenhinweisFallsNoetig`
  erscheint. Doppelt-Schutz: Session-Guard `_spendenGeprueft` **und** persistentes Feld
  `AppEinstellungen.spendenhinweisGezeigt` (Default `false`, snake `spendenhinweis_gezeigt`,
  `build_runner` regeneriert). Flag wird **synchron vor dem ersten `await`** gesetzt → kein
  Doppel-Popup durch mehrfache Post-Frame-Callbacks.
- **Punkt 4 — In-App-Logo = App-Icon** (`widgets/app_logo.dart`, neu): `WhenOpenLogo`
  (`CustomPainter`) 1:1 aus `tool/gen_icon.py` (`draw_pin`) portiert — weißer Pin + Indigo-
  Zifferblatt + grüner Mittelpunkt auf Indigo-Verlaufskachel. Ersetzt die beiden lokalen
  `_Markenzeichen` (nur `Icons.location_on`) in Home-Header (36 px) und „Über WhenOpen" (64 px).
- **l10n:** neue Keys (`qeStart*`, `qeManuell*`, `onboardingWidget*`, `spendeDialog*`), entfernte
  Onboarding-Keys (`onboardingEmail*`, `onboardingSpenden*`); `gen-l10n` neu generiert.

**Entscheidung Punkt 3:** Schwelle = **5 Orte** (`anzahl >= 5`) als „App hat sich bewährt"-Marke,
Kaffee als Primär-CTA, Feedback als Sekundär-Option — beide tauchen genau **einmal** auf und nie
wieder, da sofort persistiert.

**Verifiziert:** `flutter analyze` sauber, **90 Unit-Tests grün** (`build_runner` bestätigt das
hand-edierte `.g.dart` identisch). Adversariale Mehraugen-Review (4 Dimensionen, 13 Agenten):
Flow/l10n/Logo **ohne Findings**; beim Spenden-Trigger 6 bestätigte Punkte → behoben: Magic
Number 5 → Konstante `_spendenhinweisSchwelle`, `try/catch` um das Persistieren, Post-Frame-
Callback wird nur noch registriert, solange ein Start-Dialog aussteht, Kommentare präzisiert.
Ein vorgeschlagener „Callback nur einmal registrieren"-Fix wurde **verworfen**, weil er den
eintragszahl-abhängigen Trigger ausgehebelt hätte.

**End-to-End am Emulator (Pixel_API35) verifiziert** (Debug + Release, Screenshots):
(1) „+" öffnet die Methodenauswahl **ohne Tastatur**; „Manuell eingeben" ist die einzige Option,
die das Keyboard öffnet (Schritt 1/10, Feld fokussiert, „Zurück" → Auswahl). (2) Tutorial zeigt
**6** Seiten (statt 7) mit der Widget-Seite inkl. nummerierter Anleitung — keine E-Mail-/Spenden-
Seite mehr. (3) Mit 7 Testorten poppt nach dem Start der Dialog „Gefällt dir WhenOpen?" („…7 Orte
gespeichert…", Feedback/Später/Kaffee) auf; nach „Später" + Neustart **erscheint er nicht erneut**
(persistentes Flag greift). (4) Neues Pin-mit-Uhr-Logo im Home-Header **und** in „Über WhenOpen".
**Release-APK** signiert (`CN=WhenOpen`, v2-Scheme), 59 MB, startet ohne Crash (R8 weiterhin aus):
`build/app/outputs/flutter-apk/app-release.apk`, Kopie als `WhenOpen-v1.0.0-p15.apk` auf dem Desktop.

**Was gelernt:**
- `CustomPainter` macht das Marken-Icon **vektoriell** in-App nutzbar — ein Port der
  `gen_icon.py`-Geometrie hält In-App-Logo und Launcher-Icon ohne PNG-Asset deckungsgleich.
- Einmal-Dialoge brauchen **zwei** Sperren: Session-bool gegen Post-Frame-Doppelfeuer **und**
  persistentes Flag gegen Neustart; das persistente Flag früh setzen, nicht erst nach dem Dialog.
- „Standardweg lokal" ließ sich ohne Flow-Umbau lösen: ein vorgelagerter Auswahl-Schritt + ein
  `autofocus`-Schalter genügen, statt die 10-Schritt-Logik anzufassen.

---

## P16 — Technische Härtung nach Code-Review (2026-06-13)

Vorsichtige, **additiv-defensive** Fixes aus der 7-Dimensionen-Review — bewusst **kein** Architektur-
Umbau (App-Verhalten unverändert, nur robuster). Fachliche Lücken (Maps-Link als Freitext,
Über-Nacht-Zeiten, Feiertage) bleiben **bewusst offen** (Produktentscheidung: dafür ist die App nicht da).

**Was gebaut:**
- **Mutationen serialisiert** (`location_repository.dart`): neue `_seriell()`-Schreibsperre
  (Future-Kette) umschließt alle 10 mutierenden Methoden. Verhindert Lost-Update, wenn zwei
  read-modify-write-Operationen verschränkt laufen (z. B. zwei schnelle Taps). Reine Lesezugriffe
  bleiben frei; `_updateKategorie` (intern) wird **nicht** gewrappt → kein Deadlock.
- **Backup-Dateien gedeckelt** (`location_repository.dart`): `_begrenzeBackups()` hält nur die
  jüngsten 5 `whenopen_backup_*.json` (ISO-Zeitstempel ⇒ lexikografisch = chronologisch), aufgerufen
  nach Korrupt-Recovery und Import. Vorher wuchsen die Sicherungen unbegrenzt.
- **Exact-Alarm mit Fallback** (`widget_service.dart`): `planeNaechstenAlarm` versucht erst
  `exact: true`, fällt bei Fehler/`false` (ab Android 12+ entziehbares `SCHEDULE_EXACT_ALARM`) auf
  einen ungenauen Alarm zurück statt die Reschedule-Kette abreißen zu lassen. Kein Crash mehr,
  Widget bleibt versorgt (zusätzlich WorkManager-Netz).
- **Widget-Update-Fehler geloggt** (`locations_provider.dart`): das stille `catch (_)` in
  `_nachAenderung` schreibt jetzt `developer.log` (Fehler weiterhin **nicht** propagiert, damit
  Speichern nie scheitert — aber dauerhaft kaputte Widget-Updates werden sichtbar).
- **Über-mich-Text** (`ueber_screen.dart`): „…was bei meinen lokalen Orten gerade offen hat" →
  „…ob ich in der Mittagspause noch schnell zur Apotheke komme oder ob meine Pizzeria heute aufhat".

**Bewusst NICHT angefasst** (Risiko/Nutzen bei „App soll funktional bleiben"): state-first-Umbau
der Persistenz, `onDatenGeaendert`-Hook in den Provider-Graphen, `home_screen`-Split,
Theme-Migration (es gibt aktuell keinen Hell-Modus → kein akuter Fehler), DST-Härtung von
`naechsteAenderung` (selten, self-correcting), `allowBackup`/Auto-Backup (Verhaltensänderung vs.
„alles lokal"), APK aus der Git-Historie nehmen, CI.

**Was gelernt:**
- Eine Future-Ketten-Schreibsperre macht ein dateibasiertes Repository nebenläufigkeitssicher,
  ohne die Methodenlogik zu ändern — nur Blattmethoden wrappen, interne Helfer auslassen (Deadlock).
- „Technischer Fehler" ≠ „muss umgebaut werden": der Hell-Modus-Befund ist erst relevant, wenn
  `themeMode` überhaupt aktiviert wird — solange nur ein Theme gesetzt ist, ist es kein Defekt.

**Verifiziert:** `flutter analyze` sauber, **92 Unit-Tests grün** (90 + 2 neue: parallele
Mutationen gehen nicht verloren, Backup-Deckel ≤ 5). Noch **nicht** am Emulator/Gerät gegengeprüft
(empfohlen: Widget-Update auf einem Android-13+-Gerät mit entzogenem Exact-Alarm-Recht).

## P17 — Security- & Datenschutz-Härtung (2026-06-14)

**Auslöser:** Security-Audit aus Sicht eines Security-Experten (Multi-Agent-Review, 5 Dimensionen,
38 Befunde, jeder adversarial verifiziert und auf das lokale Bedrohungsmodell geeicht — kein
Backend/Login/Cloud/Tracking). Ergebnis: **kein kritischer/hoher Befund**; die Architektur ist
strukturell risikoarm. Umgesetzt wurden 1 Bug-Fix, mehrere Härtungen und Transparenz-Korrekturen.
Für normale Nutzung verhaltensgleich.

**Was gebaut:**
- **ReDoS-Deckel** (`opening_hours_parser.dart`): `parse()` bricht bei Rohwerten > 256 Zeichen ab.
  Quelle ist untrusted (OSM-`opening_hours`-Tag + importierte Sicherung) → kein katastrophales
  Regex-Backtracking. *(einziger im Audit hochgestufter Befund, medium)*
- **JSON-DoS-Schutz Import:** nativer Byte-Deckel beim Lesen (`BackupStorage.liesBegrenzt`, genutzt
  von `MainActivity` (SAF) und den Backup-Lesepfaden — kein unbegrenztes `readBytes`); zusätzlich
  in `LocationRepository.pruefeSicherung` Längen-Check vor `jsonDecode` (> 2 MiB) + Anzahl-Cap
  (eintraege/kategorien ≤ 1000).
- **Overpass-QL-Injection ausgeschlossen:** `osm_type` (untrusted Serverstring) wird gegen die
  Allowlist `{node, way, relation}` geprüft — in `NominatimResult.hatOsmRef` (gated den Lookup) und
  defensiv in `OverpassService.ladeTags`. `osm_id` war als `int` ohnehin unkritisch.
- **`tel:`-Whitelist** (`url_service.openPhone`): Nummer auf `[+0-9]` reduziert statt nur `[\s/()-]`
  zu entfernen — entfernt USSD/MMI-Zeichen (`#`/`*`) aus fremden/importierten Nummern; leer → kein
  Launch.
- **Koordinaten-Präzision** (`overpass_service._koord`): `toStringAsFixed(6)` → `(4)` (~11 m statt
  gebäudescharf), genug für 250–5000-m-Umkreis, weniger Standort-Exposition gegenüber Overpass.
- **User-Agent** (Nominatim + Overpass): private Gmail → Projekt-URL
  (`+https://github.com/KoelnThanh/whenopen`), Nominatim-Policy-konform.
- **`intl`** in `pubspec.yaml`: `any` → `^0.20.2` (konsistent zur Lockfile).
- **Texte:** `sichernErfolg`-String warnt vor unverschlüsselter, fremd-lesbarer Sicherung;
  `docs/privacy-policy.md` um Overpass-Standortübertragung, User-Agent-Kontakt und
  Klartext-Backup/Teilen ergänzt, „nur Suchbegriff" richtiggestellt, Stand 14.06.2026.

**Was fehlt / bewusst offen:** passwortverschlüsseltes Backup (Over-Engineering fürs Modell, kollidiert
mit Schnell-Wiederherstellen), `allowBackup="false"` (vom Audit als is_real=false eingestuft — Auto-
Backup geht ins eigene verschlüsselte Konto), Deep-Link-Filter auf `host=open` einschränken
(nur Hardening, kein Schaden).

**Was gelernt:**
- Adversariale Verifikation lohnt: von 38 Rohbefunden waren 22 Falschalarme/Bestätigungen
  (FLAG_MUTABLE-PendingIntent ist durch explizite Komponente sicher, exported Deep-Link nur
  Navigation, Widget-Prefs `MODE_PRIVATE` ohne PII) — ohne Gegenprüfung hätte man Aufwand in
  Scheinprobleme gesteckt.
- Bei einem lokalen, backendlosen Modell liegt der ganze Angriffswert in *untrusted Daten*
  (Import-Datei, OSM-Antwort) → die wirksamen Fixes sind Eingangs-Deckel + Allowlists, nicht Crypto.

**Verifiziert:** `flutter analyze` sauber, **98 Unit-Tests grün** (92 + 6 neue: ReDoS-Deckel,
Import-Größen-/Anzahllimit, osmType-Allowlist Modell+Service). Noch **nicht** am Emulator/Gerät
gegengeprüft (Logik-Fixes, durch Unit-Tests abgedeckt; empfohlen: einmal Import einer großen Datei +
Umkreissuche am Gerät gegenprüfen).

---

## P18 — UX-Redesign Ort-Anlegen (v1.1.0, 2026-06-15)

**Ausgangspunkt:** Ergonomie-Analyse aller Dialog-/Wizard-Flows (Multi-Agent, 57 Findings +
Konsistenzregeln; Vorher/Nachher-Mockups in `01-Konzept/mockups/`, maßgeblich
`whenopen-oeffnungszeiten-final.html`). Größter Reibungspunkt: der „Tag-Marathon" — Öffnungszeiten
über 7 einzelne Vollbild-Schritte (Mo–So), ~20 Taps für einen Standardladen.

**Was gebaut:**
- **„Eine Woche, ein Editor"** (`screens/quick_entry/week_hours_step.dart`, neu): EINE Wochenliste
  mit Akkordeon (immer nur ein Tag aufgeklappt) ersetzt die 7 Tag-Schritte. Drei Zeilenzustände:
  geöffnet / geschlossen / **„Noch festlegen"** (dezent gestrichelt, keine erfundenen Zeiten).
  Editor pro Tag: Segment Geöffnet/Geschlossen (neutraler Start), Zeitblöcke (Mehrblock E9),
  „＋ weiterer Zeitblock", **„Wie ‹Tag›"**-Kopierchip (einmalige Kopie via `vorschlagFuer()`,
  keine Bindung), Auto-Advance-Button „Weiter zu ‹nächster offener Tag›".
- **`QuickEntryState`**: `schritteGesamt` 10 → **4** (Name · Öffnungszeiten · Kategorie · Zusatz);
  neues `Set<Wochentag> festgelegt` (trennt „bewusst gesetzt" von „noch festlegen", nicht
  persistiert; „Noch festlegen" zählt beim Speichern als geschlossen); `naechsterUnbestimmter()`
  für die geführte Navigation. `fromLocation` (Bearbeiten) markiert alle 7 als festgelegt.
- **`QuickEntryScreen`**: Step-Mapping auf 4 Schritte, `day_entry_step.dart` entfernt (durch
  Wochen-Editor ersetzt), OSM-Übernahme markiert nur Tage MIT Zeiten als festgelegt (Lücken
  bleiben „Noch festlegen" — keine stille Geschlossen-Annahme).
- **Methodenauswahl** (`start_auswahl_step.dart`): „Orte in der Nähe" an erste Stelle.
- **Heimatadresse** (`heimat_adresse_eingabe.dart`): Debounce-**Live-Suche** (450 ms), bei genau
  einem Treffer **Auto-Übernahme**, Treffer ohne Koordinaten gefiltert, Kein-Treffer-/Fehler-Text
  statt stiller Leere; Pfeil bleibt als manueller Fallback. Strings `einstHeimatKeineTreffer`,
  `einstHeimatSuchfehler`.
- **Zeit-Obergrenze** im Block-Editor 23:30 → **23:59**.

**Was fehlt / bewusst offen:** echte Über-Mitternacht-Zeiten (Bar bis 02:00 — Datenmodell verlangt
`von < bis` je Tag; v2 via „bis nach Mitternacht"-Toggle); „Alle wie Montag"-Sammelaktion (von
Marius bewusst weggelassen); Block-3-Rückfrage-Variante bei mehrdeutigen Adressen (Live-Suche +
Auto-Übernahme decken den Fall hinreichend).

**Was gelernt:**
- Statt zwei Modi (Neuanlage geführt vs. Import/Bearbeiten frei) genügt EIN Modell: gleiche
  Liste/Bedienung, nur der **Startzustand der Zeilen** unterscheidet die Fälle. Das löst den
  lückenhaften-Import-Fall automatisch und verhindert Modus-Inkonsistenzen.
- „Keine automatischen Änderungen" wörtlich genommen: „Wie ‹Tag›" ist eine einmalige Kopie (keine
  lebende Bindung), OSM-Lücken werden nicht still geschlossen — beides vorhersehbar.

**Verifiziert:** `flutter analyze` sauber, **104 Unit-Tests grün** (98 + 6 neue für den
Wochen-Editor-State). Am **Emulator (Pixel_API35, Debug)** end-to-end per Screenshot: Methoden-
reihenfolge („Orte in der Nähe" oben), 4-Schritt-Flow, Wochen-Editor (neutraler Start, Default-Block
09–18, „Wie Montag"-Kopierchip, Auto-Advance Mo→Di→Mi, „Noch festlegen"-Zeilen).
