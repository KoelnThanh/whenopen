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
/c/flutter/bin/flutter.bat test            # 54 Unit-Tests
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
Änderung** (abgeschlossenes Feature/Paket, nicht jeder Zwischenschritt) Code **und** APK nach
GitHub pushen. Repo: `github.com/KoelnThanh/whenopen`, Branch **`main`** (direkt committen — so
ist die ganze Historie; kein PR-Flow). `gh` ist **nicht** installiert → reines `git`.

**Ablauf:**
1. Verifizieren: `flutter.bat analyze` sauber **und** `flutter.bat test` grün (Pflicht vor Release).
2. Doku: `02-MVP/inkremente.md` fortschreiben (Was gebaut / Was fehlt / Was gelernt).
3. Signierte Release-APK bauen (aus `02-MVP/when_open/`):
   ```bash
   /c/flutter/bin/flutter.bat build apk --release
   ```
4. APK in den Release-Ordner kopieren (**fester Name** = stabiler Handy-Link):
   ```bash
   cp build/app/outputs/flutter-apk/app-release.apk ../../04-Release/WhenOpen-latest.apk
   ```
5. `04-Release/CHANGELOG.md` um einen Versionseintrag ergänzen (Vorlage steht unten in der Datei).
   APK-Signatur prüfbar mit `apksigner verify --print-certs` (erwartet `CN=WhenOpen`, v2-Scheme).
6. Committen + pushen (aus dem Repo-Root `10-Projekte/whenopen/`):
   ```bash
   git add -A && git commit -m "Pxx: <kurz>" && git push origin main
   ```
   Secrets sind ge-ignored (`key.properties`, `*.jks`, `build/`) — vor `commit` trotzdem
   `git status` prüfen, dass nichts Unerwartetes/Großes mit reinrutscht.

**Download fürs Handy:** `https://github.com/KoelnThanh/whenopen/raw/main/04-Release/WhenOpen-latest.apk`
(funktioniert ohne Login nur bei **öffentlichem** Repo). Installation/Hinweise: `04-Release/README.md`.

**Wichtig / Stolpersteine:**
- **Keystore** `android/whenopen-release.jks` (+ `key.properties`) liegen **nicht** im Repo —
  separat sichern; Verlust = keine Updates mehr (selbe App-ID nicht mehr aktualisierbar).
- Die committete 59-MB-APK **bläht die Git-Historie** auf. Sauberere Alternative für später:
  **GitHub Releases** (braucht `gh` oder API-Token) bzw. **Obtainium** —
  siehe `01-Konzept/1.6-ausrollen-distribution.md`. Bei Umstieg APK aus dem Repo-Tracking nehmen.
- `git push` läuft über HTTPS (Windows Credential Manager). Schlägt Auth fehl, muss Marius den
  Push interaktiv anstoßen: im Prompt `! git push origin main` tippen.

## Regeln für dieses Projekt (Georg)

- **Testgetrieben:** Business-Logik (Services, Repository, Parser) hat Unit-Tests; Tests
  vor/mit der Implementierung. „Fertig" heißt: Tests grün **und** App läuft am Emulator.
- **Nach jeder Änderung dokumentieren** in `02-MVP/inkremente.md` (Was gebaut / Was fehlt /
  Was gelernt), damit eine neue Session ohne Kontextverlust aufsetzen kann.
- **Nach jeder großen Änderung** Code + frische Release-APK nach GitHub `main` pushen und
  `04-Release/WhenOpen-latest.apk` + `CHANGELOG.md` aktualisieren — Ablauf siehe Abschnitt
  „Release- & GitHub-Workflow".
- Nie Daten ohne Backup überschreiben; JSON-Schreiben atomar (write-then-rename) — schon im
  `LocationRepository` umgesetzt.
- Deutsche Code-Kommentare, saubere Ordnerstruktur.
- Systeminstallationen laufen über Admin-Tickets (`40-Konfig/_Tickets/`), nicht inline.
