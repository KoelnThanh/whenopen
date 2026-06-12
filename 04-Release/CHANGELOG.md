# WhenOpen — Changelog

Release-Dokumentation. Neueste Version oben. Die jeweils aktuelle, installierbare Datei liegt
als [`WhenOpen-latest.apk`](WhenOpen-latest.apk) in diesem Ordner (signiert, `CN=WhenOpen`).
Installationshinweise: siehe [`README.md`](README.md).

> Versionsschema: `vMAJOR.MINOR.PATCH` · interne Paket-Kürzel (`Pxx`) verweisen auf
> `02-MVP/inkremente.md`.

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
