# WhenOpen — Release-Ordner

Hier liegt die jeweils **aktuelle, installierbare APK** plus Release-Dokumentation.

| Datei | Zweck |
|---|---|
| [`WhenOpen-latest.apk`](WhenOpen-latest.apk) | Neueste signierte Version (fester Name → stabiler Download-Link) |
| [`CHANGELOG.md`](CHANGELOG.md) | Versionsverlauf / Release Notes |
| `play-store-listing.md` | Vorbereiteter Play-Store-Text |
| `onepager.md` | Kurzvorstellung |

## Aufs Smartphone holen

**Direkter Download-Link** (Branch `main`):

```
https://github.com/KoelnThanh/whenopen/raw/main/04-Release/WhenOpen-latest.apk
```

> Hinweis: Solange das Repo **privat** ist, funktioniert der Link nur eingeloggt
> (GitHub-App/Browser mit deinem Konto). Bei einem **öffentlichen** Repo geht er ohne Login.

**Installieren (Android):**
1. Link auf dem Handy öffnen → APK herunterladen.
2. Datei antippen → ggf. „Aus dieser Quelle installieren erlauben" bestätigen.
3. „Installieren" → fertig. Updates installieren sich **über** die alte Version (kein
   Datenverlust), solange dieselbe Signatur (`CN=WhenOpen`) verwendet wird.

## Hinweise

- Die APK hat **R8/Minify aus** (bewusst, wegen früherem WorkManager-Release-Crash).
- Der **Keystore** (`android/whenopen-release.jks`) liegt **nicht** im Repo — separat sichern,
  sonst sind keine Updates mehr möglich.
- Sauberere Alternative zum Mitcommitten der APK (vermeidet Repo-Aufblähung): **GitHub Releases**
  oder **Obtainium** — siehe `01-Konzept/1.6-ausrollen-distribution.md`.
