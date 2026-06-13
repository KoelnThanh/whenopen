# WhenOpen — Changelog

Release-Dokumentation. Neueste Version oben. Die installierbare APK hängt als Asset `WhenOpen.apk`
am jeweiligen [GitHub Release](https://github.com/KoelnThanh/whenopen/releases/latest); stabiler
Direktlink zur neuesten Version (signiert, `CN=WhenOpen`):
`https://github.com/KoelnThanh/whenopen/releases/latest/download/WhenOpen.apk`.
Installationshinweise: siehe [`README.md`](README.md).

> Versionsschema: `vMAJOR.MINOR.PATCH` · interne Paket-Kürzel (`Pxx`) verweisen auf
> `02-MVP/inkremente.md`.

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
