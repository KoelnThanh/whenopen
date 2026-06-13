# WhenOpen — Release-Ordner

Hier liegt die jeweils **aktuelle, installierbare APK** plus Release-Dokumentation.

| Datei | Zweck |
|---|---|
| [`CHANGELOG.md`](CHANGELOG.md) | Versionsverlauf / Release Notes |
| `play-store-listing.md` | Vorbereiteter Play-Store-Text |
| `onepager.md` | Kurzvorstellung |

> Die installierbare **APK liegt nicht mehr in diesem Ordner**, sondern als Asset `WhenOpen.apk`
> am jeweiligen [GitHub Release](https://github.com/KoelnThanh/whenopen/releases/latest)
> (vermeidet das Aufblähen der Git-Historie).

## Aufs Smartphone holen

**Direkter Download-Link** (zeigt immer auf die neueste Version):

```
https://github.com/KoelnThanh/whenopen/releases/latest/download/WhenOpen.apk
```

> Der Link braucht keinen Versionsnamen — GitHub leitet automatisch auf das neueste Release.
> Bei öffentlichem Repo funktioniert er ohne Login.

**Installieren (Android):**
1. Link auf dem Handy öffnen → APK herunterladen.
2. Datei antippen → ggf. „Aus dieser Quelle installieren erlauben" bestätigen.
3. „Installieren" → fertig. Updates installieren sich **über** die alte Version (kein
   Datenverlust), solange dieselbe Signatur (`CN=WhenOpen`) verwendet wird.

## Hinweise

- Die APK hat **R8/Minify aus** (bewusst, wegen früherem WorkManager-Release-Crash).
- Der **Keystore** (`android/whenopen-release.jks`) liegt **nicht** im Repo — separat sichern,
  sonst sind keine Updates mehr möglich.
- Die Verteilung läuft über **GitHub Releases** (Asset `WhenOpen.apk`) — die APK wird **nicht**
  mehr ins Repo committet. Für automatische Update-Erkennung am Handy eignet sich **Obtainium**
  (liest GitHub-Releases) — siehe `01-Konzept/1.6-ausrollen-distribution.md`.
