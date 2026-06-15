# WhenOpen — Changelog

Release-Dokumentation. Neueste Version oben. Die installierbare APK hängt als Asset `WhenOpen.apk`
am jeweiligen [GitHub Release](https://github.com/KoelnThanh/whenopen/releases/latest); stabiler
Direktlink zur neuesten Version (signiert, `CN=WhenOpen`):
`https://github.com/KoelnThanh/whenopen/releases/latest/download/WhenOpen.apk`.
Installationshinweise: siehe [`README.md`](README.md).

> Versionsschema: `vMAJOR.MINOR.PATCH` · interne Paket-Kürzel (`Pxx`) verweisen auf
> `02-MVP/inkremente.md`.

---

## v1.1.0 — 2026-06-15 (P18: UX-Redesign Ort-Anlegen)

**APK:** GitHub-Release-Asset [`WhenOpen.apk`](https://github.com/KoelnThanh/whenopen/releases/download/v1.1.0/WhenOpen.apk)
· signiert (`CN=WhenOpen`, APK Signature Scheme v2) · ~59 MB · App-ID `com.whenopen.when_open` ·
`versionName` 1.1.0 (`versionCode` 4).

**Hintergrund:** Ergonomie-Analyse aller Dialog-/Wizard-Flows (Vorher/Nachher-Mockups in
`01-Konzept/mockups/`). Der größte Reibungspunkt war der „Tag-Marathon": Öffnungszeiten liefen
über **sieben einzelne Vollbild-Schritte** (Mo–So). Diese werden zu **einer Wochenübersicht**.

**Neu / geändert:**
- **Öffnungszeiten in einem Schritt** („Eine Woche, ein Editor"): statt 7 Vollbild-Seiten eine
  Wochenliste mit Akkordeon-Editor. Der Schnelleintrag schrumpft von **10 auf 4 Schritte**; ein
  Standardladen ist in deutlich weniger Taps angelegt. Jeder Tag ist *geöffnet*, *geschlossen*
  oder *„Noch festlegen"* (nichts wird still angenommen). „Weiter" führt automatisch zum nächsten
  offenen Tag, sodass sich die Woche von oben aufbaut. **„Wie ‹Tag›"** kopiert die Zeiten eines
  früheren Tages in einem Tap (einmalige Kopie, keine Bindung). Mehrblock/Mittagspause (E9)
  bleibt vollständig erhalten. Dasselbe Modell gilt für Neuanlage, OSM-Import (Lücken bleiben
  „Noch festlegen") und Bearbeiten — kein Sondermodus mehr.
- **Methodenauswahl:** „Orte in der Nähe" steht jetzt **an erster Stelle** (bequemster Weg).
- **Heimatadresse:** **Live-Suche** statt Pflicht-Pfeil — wer tippt, sieht automatisch Treffer.
  Ein **eindeutiger Treffer wird direkt übernommen**, sodass eine getippte, aber nicht
  bestätigte Adresse nicht mehr still verloren geht. Kein Treffer / Suchfehler werden benannt
  statt verschluckt.
- **Zeit-Obergrenze** auf **23:59** angehoben (vorher 23:30), damit Läden bis kurz vor
  Mitternacht erfassbar sind. (Echte Über-Mitternacht-Zeiten bleiben bewusst v2.)

**Qualität:** `flutter analyze` sauber, **104 Unit-Tests grün** (6 neue: Wochen-Editor-State —
`naechsterUnbestimmter`, `vorschlagFuer`, Bearbeiten-Festlegung). Am Emulator (Pixel_API35,
Debug) end-to-end per Screenshot verifiziert: Methodenreihenfolge, 4-Schritt-Flow, Wochen-Editor
(neutraler Start, Default-Block, „Wie Montag"-Kopie, Auto-Advance).

**Basis:** baut auf v1.0.2 (P17) auf. Details: `02-MVP/inkremente.md` (Abschnitt P18).

---

## v1.0.2 — 2026-06-14 (P17: Security- & Datenschutz-Härtung)

**APK:** GitHub-Release-Asset [`WhenOpen.apk`](https://github.com/KoelnThanh/whenopen/releases/download/v1.0.2/WhenOpen.apk)
· signiert (`CN=WhenOpen`, APK Signature Scheme v2) · ~59 MB · App-ID `com.whenopen.when_open` ·
`versionName` 1.0.2 (`versionCode` 3).

**Hintergrund:** Security-/Datenschutz-Audit aus Sicht eines Security-Experten (lokales
Bedrohungsmodell: kein Backend/Login/Cloud). Kein kritischer/hoher Befund — die Architektur
ist risikoarm. Umgesetzt wurden ein Bug-Fix und mehrere Härtungen sowie
Transparenz-Korrekturen. Verhalten für normale Nutzung unverändert.

**Behoben / gehärtet (unter der Haube):**
- **ReDoS-Schutz** im `opening_hours`-Parser: untrusted Werte (OSM-Tag/Import) werden vor dem
  Regex auf eine Länge gedeckelt — kein katastrophales Backtracking mehr.
- **JSON-DoS-Schutz** beim Wiederherstellen: Importdateien werden nativ gedeckelt gelesen
  (kein unbegrenztes `readBytes`) und vor dem Parsen auf Größe/Anzahl geprüft.
- **Overpass-QL-Injection** ausgeschlossen: der OSM-Objekttyp wird gegen eine Allowlist
  (`node`/`way`/`relation`) geprüft, bevor er in die Abfrage geht.
- **`tel:`-Härtung:** Telefonnummern werden vor dem Wählen auf echte Wähl-Zeichen reduziert
  (entfernt u. a. `#`/`*` aus fremden/importierten Nummern).

**Datenschutz / Transparenz:**
- **Standort sparsamer:** die Umkreissuche überträgt die Position nur noch auf ~11 m gerundet
  (statt gebäudescharf) an `overpass-api.de`.
- **Keine private Mail mehr nach außen:** der HTTP-User-Agent an OSM/Overpass nennt jetzt eine
  Projekt-URL statt der privaten Adresse.
- **Sichern-Hinweis:** beim Sichern wird klar gesagt, dass die Datei unverschlüsselt im offenen
  `Download/WhenOpen` liegt und für andere Apps lesbar ist.
- **Datenschutzerklärung** korrigiert/ergänzt: Overpass-Umkreissuche (Standortübertragung),
  User-Agent-Kontakt, unverschlüsselte Backup-/Teilen-Kopien.
- **`intl`** auf `^0.20.2` gepinnt (Supply-Chain-Hygiene, konsistent zur Lockfile).

**Qualität:** `flutter analyze` sauber, **98 Unit-Tests grün** (6 neue: ReDoS-Deckel,
Import-Größen-/Anzahllimit, osmType-Allowlist).

**Basis:** baut auf v1.0.1 (P16) auf. Details: `02-MVP/inkremente.md` (Abschnitt P17).

---

## v1.0.1 — 2026-06-13 (P16: Technische Härtung)

**APK:** GitHub-Release-Asset [`WhenOpen.apk`](https://github.com/KoelnThanh/whenopen/releases/download/v1.0.1/WhenOpen.apk)
· signiert (`CN=WhenOpen`, APK Signature Scheme v2) · ~59 MB · App-ID `com.whenopen.when_open` ·
`versionName` 1.0.1 (`versionCode` 2). **Erstes Release über GitHub Releases** (nicht mehr im Repo).

**Neu / geändert:**
- **Über mich** — Vorstellungstext konkretisiert: „…ob ich in der Mittagspause noch schnell zur
  Apotheke komme oder ob meine Pizzeria heute aufhat…" statt der abstrakten Formulierung.
- **Unter der Haube (Robustheit, Verhalten unverändert):** Daten-Mutationen werden serialisiert
  (kein „Lost Update" bei schnellen, verschränkten Speichervorgängen); alte Sicherungs-Backups
  (`whenopen_backup_*.json`) werden auf die jüngsten 5 begrenzt; der grenzgenaue Widget-Alarm
  fällt bei entzogenem Exact-Alarm-Recht (Android 12+) auf einen ungenauen Alarm zurück statt
  auszufallen; fehlgeschlagene Widget-Updates werden jetzt protokolliert.

**Bewusst offen gelassen** (Produktentscheidung): Google-Maps-Link als Freitext, Über-Nacht-
Öffnungszeiten, Feiertage/Ausnahmen.

**Qualität:** `flutter analyze` sauber, **92 Unit-Tests grün** (2 neue: Mutations-Serialisierung,
Backup-Deckel), am Emulator (Pixel_API35) regressiv verifiziert (Start ohne Crash, Mutation
committet auf Platte, Über-Text sichtbar). R8/Minify weiterhin aus.

**Basis:** baut auf v1.0.0 (P15) auf. Details: `02-MVP/inkremente.md` (Abschnitt P16).

---

## v1.0.0 — 2026-06-12 (P15: UX-Feinschliff)

**APK:** `WhenOpen-latest.apk` · signiert (`CN=WhenOpen`, APK Signature Scheme v2) · ~59 MB ·
App-ID `com.whenopen.when_open` · `versionName` 1.0.0 (`versionCode` 1).

**Neu / geändert:**
- **Ort anlegen** beginnt jetzt mit einer Methodenauswahl (kein sofortiges Tastatur-Aufpoppen):
  „Ort suchen" (OpenStreetMap) und „Orte in der Nähe" (Umkreis) als Standardwege, „Manuell
  eingeben" als dritte, dezente Option. Die Tastatur öffnet nur noch bei „Manuell".
- **Tutorial:** neue Seite zum **Home-Widget** (mit Schritt-für-Schritt-Anleitung) — die App
  entfaltet ihren Nutzen erst als Widget auf dem Startbildschirm.
- **Unterstützen/Feedback** erscheint nicht mehr im Tutorial, sondern als einmaliger Dialog
  **erst ab dem 5. gespeicherten Ort** (Kaffee + Feedback). Erscheint nie doppelt.
- **In-App-Logo** zeigt jetzt den Pin **mit Uhr** (wie das App-Icon) im Home-Header und in
  „Über WhenOpen" — statt des nackten Pins.

**Qualität:** `flutter analyze` sauber, 90 Unit-Tests grün, adversariale Code-Review,
am Emulator (Debug + Release) end-to-end per Screenshot verifiziert. R8/Minify weiterhin aus.

**Basis:** baut auf P01–P14 auf (Datenmodell, Widget, OSM-Import, Umkreissuche, Backup/Teilen/
Wiederherstellen, „Über WhenOpen", Erstnutzer-Tutorial, Indigo-Rebrand v0.3). Details:
`02-MVP/inkremente.md`.

---

<!-- Vorlage für künftige Einträge:

## vX.Y.Z — JJJJ-MM-TT (Pxx: Titel)

**APK:** `WhenOpen-latest.apk` · signiert · ~XX MB · versionName X.Y.Z (versionCode N).

**Neu / geändert:**
- …

**Qualität:** …
-->
