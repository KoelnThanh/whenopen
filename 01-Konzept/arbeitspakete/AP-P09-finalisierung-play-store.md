# Arbeitspaket

## AP-P09 — Finalisierung und Play Store Release

| Feld | Wert |
|---|---|
| **Plan-ID** | P09 |
| **Spec-Referenz** | Rahmenbedingungen (Play Store), Erfolgskriterien |
| **Komponente** | Release |
| **Agent** | Georg |
| **Geschätzte Größe** | ~400 LOC · ~60K Tokens |
| **Abhängig von** | P06, P07, P08b |
| **Übergabe an** | — |

---

## Ziel

Die App für den Google Play Store fertigstellen: App-Icon, Splash Screen, alle Strings lokalisiert, Release-Build signiert, Play Store Listing mit Screenshots, Privacy Policy verlinkt.

---

## Eingaben

- Vollständige App aus P01–P08b
- `1.1-spezifikation.md` → Erfolgskriterien (Play Store veröffentlicht, LinkedIn, GitHub)
- Google Play Console (Konto vorausgesetzt — $25 Developer-Gebühr, vom Auftraggeber einzurichten)

---

## Aufgaben

1. **App-Icon erstellen**
   - Icon-Design: einfaches, erkennbares Icon (z.B. Uhr + grüner Haken oder geöffnetes Schild)
   - Varianten erzeugen: `flutter_launcher_icons` Package nutzen
   - Benötigte Größen: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi + Adaptive Icon für Android 8+
   - `ic_launcher_foreground.png` und `ic_launcher_background.xml` für Adaptive Icon

2. **Splash Screen konfigurieren**
   - `flutter_native_splash` Package nutzen
   - Einfacher Splash: weißer/heller Hintergrund + App-Icon zentriert
   - Konfiguration in `pubspec.yaml` (flutter_native_splash-Sektion)

3. **Alle Strings auf Vollständigkeit prüfen**
   - `app_de.arb` durchgehen: kein hardcodierter Text in der gesamten App
   - Play Store-spezifische Strings ergänzen: App-Name "WhenOpen", kurze Beschreibung (80 Zeichen), lange Beschreibung (4.000 Zeichen)
   - `dart analyze` — keine Fehler, keine Warnungen

4. **Release-Build konfigurieren und signieren**
   - Keystore erstellen: `keytool -genkey -v -keystore whenopen-release.jks -alias whenopen -keyalg RSA -keysize 2048 -validity 10000`
   - `android/key.properties` anlegen (wird nicht ins Git eingecheckt — `.gitignore` prüfen)
   - `android/app/build.gradle` um Signing-Konfiguration ergänzen
   - Release-Build: `flutter build appbundle --release`
   - AAB-Datei überprüfen: Größe < 150 MB (Grenze für Play Store)

5. **Privacy Policy erstellen und hosten**
   - Inhalt: App sammelt keine personenbezogenen Daten, keine Weitergabe an Dritte, lokale Speicherung
   - Hosting: GitHub Repository als `docs/privacy-policy.md` + GitHub Pages aktivieren → öffentliche URL
   - URL notieren für Play Store Eintrag

6. **Play Store Listing anlegen**
   - App-Name: "WhenOpen"
   - Kurzbeschreibung (80 Zeichen): z.B. "Öffnungszeiten deiner Lieblingsorte immer im Blick"
   - Lange Beschreibung (4.000 Zeichen): Kernfunktionen, Use Cases, Personas
   - Kategorie: "Produktivität"
   - Screenshots: mind. 2 Hochformat-Screenshots (1080×1920 oder 1080×2160)
     - Screenshot 1: Widget-Screen mit mehreren Einträgen (offen/geschlossen)
     - Screenshot 2: Schnelleintrag-Flow
     - Screenshot 3 (optional): Detailansicht
   - Feature Graphic (1024×500) optional aber empfohlen
   - Privacy Policy URL eintragen

7. **Release einreichen**
   - Interner Test-Track: AAB hochladen, 1–2 Testnutzer einladen
   - Nach Testphase: Closed Testing oder direkt Production
   - Review-Zeit einkalkulieren: Google braucht typischerweise 1–7 Tage

8. **GitHub Repository vorbereiten**
   - `README.md` mit: Projektbeschreibung, Screenshots, "Built with Flutter", Link zum Play Store
   - Repository auf Public setzen
   - Tag für erste Release-Version: `git tag v1.0.0`

---

## Lieferobjekt

- `android/app/src/main/res/mipmap-*/ic_launcher*.png` (alle Größen)
- `pubspec.yaml` — flutter_native_splash + flutter_launcher_icons konfiguriert
- `when_open-release.aab` (signierter Release-Build)
- `docs/privacy-policy.md` + GitHub Pages URL
- Play Store Listing — vollständig ausgefüllt, bereit zur Einreichung
- `README.md` auf GitHub

---

## Akzeptanzkriterien

- [ ] `flutter build appbundle --release` läuft ohne Fehler
- [ ] App-Icon ist in allen Größen vorhanden (kein Standard-Flutter-Icon)
- [ ] Splash Screen zeigt WhenOpen-Icon (kein Flutter-Standard-Splash)
- [ ] `dart analyze` — keine Fehler, keine Warnungen
- [ ] Privacy Policy ist öffentlich erreichbar (HTTPS-URL)
- [ ] Play Store Listing: alle Pflichtfelder ausgefüllt, Privacy Policy URL eingetragen
- [ ] AAB-Datei erfolgreich auf Play Console hochgeladen
- [ ] Mindestens 2 Screenshots im Listing vorhanden
- [ ] GitHub Repository ist öffentlich mit README

---

## Hinweise

- `whenopen-release.jks` (Keystore-Datei) niemals ins Git einchecken — geht der Keystore verloren, kann die App nicht mehr aktualisiert werden. Sicher aufbewahren (z.B. Passwortmanager oder verschlüsseltes Backup).
- `android/key.properties` ebenfalls nicht ins Git — `.gitignore` prüfen vor dem ersten Commit dieses Pakets
- Google Play Developer-Konto muss vor Beginn dieses Pakets vorhanden sein — Einrichtung dauert 1–2 Tage nach Zahlung der $25
- App-Icon: wenn kein Grafikdesign-Tool verfügbar → Canva oder einfaches SVG in Inkscape, dann in PNG exportieren. Ein schlichtes Icon ist besser als gar keins.
- Die lange App-Beschreibung im Play Store ist wichtig für die App-Store-Optimierung (ASO) — konkrete Use Cases und Personas einbauen (aus der Spezifikation)
- Erste Version als "Early Access" oder mit wenigen Testern starten — dann Review-Feedback abwarten bevor breites Rollout
