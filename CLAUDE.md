# Agenten-Instruktionen: WhenOpen

Teil des Gesamtsystems. Zuerst lesen: `C:\Users\nnguy\Claude\_System\CLAUDE.md`,
dann die Bereichsregeln `C:\Users\nnguy\Claude\10-Projekte\CLAUDE.md`.

## Was ist WhenOpen?

Android-App (Flutter, nur Android, API 26+) mit Home-Widget, die persönliche
Öffnungszeiten **lokal** speichert und auf einen Blick zeigt, was gerade offen ist.
Kein Backend, kein Login, keine Cloud. JSON-Persistenz. OSM/Nominatim-Import.

- Konzept/Anforderungen: `01-Konzept/1.1-spezifikation.md`, `1.2-plan.md`
- **Scope-Entscheidungen E9–E16** (maßgeblich): `01-Konzept/1.3-scope-entscheidungen.md`
- Arbeitspakete: `01-Konzept/arbeitspakete/`
- **Inkrement-Protokoll (Stand je AP): `02-MVP/inkremente.md`** ← hier zuerst nachsehen
- App-Code: `02-MVP/when_open/`

## Aktueller Stand (2026-06-12)

P01–P15 implementiert und **end-to-end am Emulator verifiziert** (Debug + Release; siehe
`02-MVP/inkremente.md`). 90 Unit-Tests grün, `flutter analyze` sauber. Signierte Release-APK
gebaut (`CN=WhenOpen`, v2). Offen: nur kontoabhängige Play-Store-Schritte sowie die
Verteilungs-/Ausroll-Entscheidungen (`01-Konzept/1.6-ausrollen-distribution.md`).

## Widget-Architektur (seit v1.4.0 / P22)

Das Home-Widget rechnet **nativ**: `OeffnungsLogik.kt` (Kotlin-Spiegel von
`OpenStatusService`) liest die App-Datei direkt (`WidgetDaten.kt`), `WidgetTakt.kt` plant
den Alarm auf die nächste Öffnungs-/Schließgrenze. Dart stößt nur `HomeWidget.updateWidget` an.
**Änderungen an der Öffnungslogik immer in Dart UND Kotlin nachziehen** (gespiegelte Tests).

## Entwicklungsumgebung

| Sache | Wert |
|---|---|
| Flutter | `C:\flutter\bin\flutter.bat` (3.44.1) — **nicht im PATH**, direkt aufrufen |
| Android SDK / adb | `C:\Users\nnguy\AppData\Local\Android\Sdk\platform-tools\adb.exe` |
| Emulator | `Pixel_API35` (Android 15) — `flutter.bat emulators --launch Pixel_API35` |
| App-ID | `com.whenopen.when_open` |
| Datendatei (Gerät) | `/data/data/com.whenopen.when_open/app_flutter/whenopen_data.json` |

Claude-Code-Shell ist **bash** (Git/MSYS) auf Windows. Bei adb-Befehlen mit Geräte-Pfaden
(z. B. `/sdcard/...`) **`export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'`** setzen,
sonst macht MSYS aus `/sdcard/x.png` einen Windows-Pfad.

## Häufige Befehle (aus `02-MVP/when_open/`)

```bash
/c/flutter/bin/flutter.bat test            # Dart-Unit-/Widget-Tests
(cd android && ./gradlew :app:testDebugUnitTest)   # Kotlin-Tests der Widget-Logik
/c/flutter/bin/flutter.bat analyze         # Lint
/c/flutter/bin/flutter.bat build apk --debug
ADB=/c/Users/nnguy/AppData/Local/Android/Sdk/platform-tools/adb.exe
$ADB install -r build/app/outputs/flutter-apk/app-debug.apk
$ADB shell monkey -p com.whenopen.when_open -c android.intent.category.LAUNCHER 1
```

**Testdaten vorladen** (kanonisch: `02-MVP/testdaten.json`, 7 Orte/3 Kategorien):
```bash
$ADB shell am force-stop com.whenopen.when_open
$ADB shell "run-as com.whenopen.when_open sh -c 'cat > app_flutter/whenopen_data.json'" < 02-MVP/testdaten.json
# run-as kann /sdcard NICHT lesen → per stdin pipen, nicht push+cp
```

**Screenshot:** `$ADB shell screencap -p /sdcard/s.png && $ADB pull /sdcard/s.png ./s.png`
(PowerShell-`>`-Redirect zerstört Binärdaten — nie nutzen).
Screencaps sind 1080×2400; Tap-Koordinaten via `uiautomator dump` holen, nicht aus dem
skalierten Bild schätzen.

**Deep-Link testen:**
`$ADB shell am start -a android.intent.action.VIEW -d "whenopen://app/open/ort-buergeramt" com.whenopen.when_open`

## Release- & GitHub-Workflow (nach jeder großen Änderung)

Marius will neue Stände **schnell auf dem Smartphone** testen. Daher gilt: **nach jeder großen
Änderung** (abgeschlossenes Feature/Paket, nicht jeder Zwischenschritt) Code nach GitHub `main`
pushen **und** die signierte APK als **GitHub-Release-Asset** veröffentlichen. Repo:
`github.com/KoelnThanh/whenopen`, Branch **`main`** (direkt committen — kein PR-Flow). `gh` ist
**nicht** installiert → Releases laufen über die **GitHub-API** mit dem Token aus dem Windows
Credential Manager (`git credential fill`).

> **Die APK wird NICHT mehr ins Repo committet** (`04-Release/*.apk` ist ge-ignored — sonst bläht
> jede 59-MB-Version die Historie auf). Sie hängt als Asset **`WhenOpen.apk`** (konstanter Name!)
> am Release; das ergibt den stabilen Latest-Link.

**Ablauf:**
1. Verifizieren: `flutter.bat analyze` sauber **und** `flutter.bat test` grün (Pflicht vor Release).
2. Version in `pubspec.yaml` erhöhen (`versionName+versionCode`, z. B. `1.0.1+2`) — der
   `versionCode` MUSS steigen, damit Android/Obtainium es als Update erkennt.
3. Doku: `02-MVP/inkremente.md` fortschreiben; `04-Release/CHANGELOG.md` um einen Versionseintrag
   ergänzen (Vorlage steht unten in der Datei).
4. Signierte Release-APK bauen (aus `02-MVP/when_open/`):
   ```bash
   /c/flutter/bin/flutter.bat build apk --release
   ```
   Signatur prüfbar mit `apksigner verify --print-certs` (erwartet `CN=WhenOpen`, v2-Scheme).
5. Code committen + pushen (aus dem Repo-Root `10-Projekte/whenopen/`):
   ```bash
   git add -A && git commit -m "Pxx: <kurz>" && git push origin main
   ```
   Secrets/APK sind ge-ignored (`key.properties`, `*.jks`, `build/`, `04-Release/*.apk`) — vor
   `commit` trotzdem `git status` prüfen, dass nichts Unerwartetes mit reinrutscht.
6. GitHub Release anlegen + APK als Asset hochladen (Token **nie** ausgeben; aus `when_open/`):
   ```bash
   TOKEN=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill 2>/dev/null | sed -n 's/^password=//p')
   RESP=$(curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
     https://api.github.com/repos/KoelnThanh/whenopen/releases \
     -d '{"tag_name":"vX.Y.Z","target_commitish":"main","name":"WhenOpen vX.Y.Z","body":"..."}')
   RELID=$(echo "$RESP" | sed -n 's/.*"id": *\([0-9]\+\).*/\1/p' | head -1)
   export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'
   curl -s -X POST -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/vnd.android.package-archive" \
     --data-binary @build/app/outputs/flutter-apk/app-release.apk \
     "https://uploads.github.com/repos/KoelnThanh/whenopen/releases/$RELID/assets?name=WhenOpen.apk"
   ```
   Asset-Name MUSS `WhenOpen.apk` sein (konstant über alle Releases).

**Download fürs Handy (stabil, immer neueste Version):**
`https://github.com/KoelnThanh/whenopen/releases/latest/download/WhenOpen.apk`
(funktioniert ohne Login nur bei **öffentlichem** Repo). Installation/Hinweise: `04-Release/README.md`.

**Wichtig / Stolpersteine:**
- **Keystore** `android/whenopen-release.jks` (+ `key.properties`) liegen **nicht** im Repo —
  separat sichern; Verlust = keine Updates mehr (selbe App-ID nicht mehr aktualisierbar).
- Asset-Name `WhenOpen.apk` ist Pflicht — andernfalls bricht der `releases/latest/download/`-Link.
- Die **Alt-Historie** enthält noch die früher committeten APKs (Commits bis v1.0.1). Bewusst
  belassen; echte Bereinigung bräuchte `git filter-repo` + Force-Push (separat, riskant).
- API/`git push` laufen über HTTPS (Windows Credential Manager). Schlägt Auth fehl, muss Marius
  interaktiv anstoßen: im Prompt `! git push origin main` tippen.

## Regeln für dieses Projekt (Georg)

- **Testgetrieben:** Business-Logik (Services, Repository, Parser) hat Unit-Tests; Tests
  vor/mit der Implementierung. „Fertig" heißt: Tests grün **und** App läuft am Emulator.
- **Nach jeder Änderung dokumentieren** in `02-MVP/inkremente.md` (Was gebaut / Was fehlt /
  Was gelernt), damit eine neue Session ohne Kontextverlust aufsetzen kann.
- **Nach jeder großen Änderung** Code nach GitHub `main` pushen, `CHANGELOG.md` ergänzen und die
  signierte APK als **GitHub-Release-Asset** `WhenOpen.apk` veröffentlichen (APK **nicht** mehr ins
  Repo committen) — Ablauf siehe Abschnitt „Release- & GitHub-Workflow".
- Nie Daten ohne Backup überschreiben; JSON-Schreiben atomar (write-then-rename) — schon im
  `LocationRepository` umgesetzt.
- Deutsche Code-Kommentare, saubere Ordnerstruktur.
- Systeminstallationen laufen über Admin-Tickets (`40-Konfig/_Tickets/`), nicht inline.
