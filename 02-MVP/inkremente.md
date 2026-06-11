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
