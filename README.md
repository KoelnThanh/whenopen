# WhenOpen

> Persönliche Öffnungszeiten auf einen Blick – Android-App mit Home-Widget.

**WhenOpen** speichert die Öffnungszeiten der Orte, die du regelmäßig brauchst – Ärzte,
Behörden, Supermärkte, Freizeit – lokal auf dem Gerät und zeigt dir auf einem dedizierten
Widget-Screen sofort, was *gerade* offen ist. Kein Suchen, kein Nachschlagen in Google Maps,
kein Backend. Ein fokussierter persönlicher Zwischenspeicher, der täglich nützlich ist.

- **Plattform:** Android (API 26 / Android 8.0+), iOS architektonisch vorbereitet
- **Tech:** Flutter (Dart), lokale JSON-Persistenz, vollständig offline
- **Keine Cloud, kein Login, keine KI** – alle Logik ist deterministisch und läuft auf dem Gerät

## Status

🟡 **Konzeptphase abgeschlossen, Umsetzung steht aus.**
Die Spezifikation und die Arbeitspakete (P01–P09) sind fertig; das Flutter-Scaffold folgt,
sobald die Toolchain steht. Dies ist ein Hobby-/Sichtbarkeitsprojekt (Vibe-Coding-Nachweis)
ohne harte Deadline.

## Kernfunktionen (MVP)

- **Schnelleintrag** in unter 2 Minuten – sequenzieller Wochendialog Mo–So mit flexiblen
  Zeitblöcken pro Tag (mehrere Pausen möglich)
- **Home-Widget** mit Tagesübersicht: oben offen, unten geschlossen; Tippen öffnet die Detailansicht
- **„Jetzt offen?"-Logik** als Stufenfunktion – ereignisgetriebene Aktualisierung statt Polling
  (grenzgenaue Weckung via `AlarmManager` + `WorkManager`-Sicherheitsnetz)
- **Kategorien & Filter** in Liste und Widget (verwaltete Kategorien mit stabiler ID)
- **Optionaler OSM/Nominatim-Import** mit manueller Bestätigung (Google Places ist ToS-inkompatibel)
- **Google-Maps-Direktlink** pro Eintrag, Export der JSON via Share-Intent, Löschen mit Undo

## Projektstruktur

```
00-Vorprojekt/   Idee, Definition of Ready, Go/No-Go
01-Konzept/      Spezifikation, Plan, Scope-Entscheidungen, Arbeitspakete, Mockups, Personas
02-MVP/          Erster funktionierender Stand (Flutter-App folgt hier)
03-Produktion/   Fertiges Produkt, Tests
04-Release/      Installer, Release Notes, Changelog
05-Wartung/      Laufende Pflege
```

## Dokumentation

| Dokument | Inhalt |
|---|---|
| [`01-Konzept/1.1-spezifikation.md`](01-Konzept/1.1-spezifikation.md) | Vollständige Projektspezifikation (Workflows, Datenmodell, NFRs) |
| [`01-Konzept/1.2-plan.md`](01-Konzept/1.2-plan.md) | Umsetzungsplan |
| [`01-Konzept/1.3-scope-entscheidungen.md`](01-Konzept/1.3-scope-entscheidungen.md) | Scope-Entscheidungen E9–E16 (überschreiben Teile der Spec) |
| [`01-Konzept/arbeitspakete/`](01-Konzept/arbeitspakete/) | Arbeitspakete P01–P09 |
| [`01-Konzept/personas/`](01-Konzept/personas/) | 7 Personas als Mockups |

---

*Entwickelt mit KI-Unterstützung (Vibe-Coding). Lizenz: noch offen.*
