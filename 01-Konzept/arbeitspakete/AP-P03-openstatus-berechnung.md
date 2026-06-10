# Arbeitspaket

## AP-P03 — OpenStatus-Berechnung

| Feld | Wert |
|---|---|
| **Plan-ID** | P03 |
| **Spec-Referenz** | Zustandslogik "Jetzt geöffnet?", Edge Cases |
| **Komponente** | Business-Logic-Layer |
| **Agent** | Georg |
| **Geschätzte Größe** | ~600 LOC · ~90K Tokens |
| **Abhängig von** | P02 |
| **Übergabe an** | P04, P05, P06 |

> ⚠️ **Aktualisiert 2026-06-10 (E9, E16):** `isOpenNow` rechnet über die **Zeitblock-Liste** (kein `pauseVon/pauseBis` mehr). Neue Funktion **`naechsteAenderung(locations, now)`** liefert die nächste Block-Grenze fürs Update-Scheduling (E16). Maßgeblich: AP-Zeile in [`../1.3-scope-entscheidungen.md`](../1.3-scope-entscheidungen.md).

---

## Ziel

Den `OpenStatusService` implementieren — die Kernlogik der App, die für jeden gespeicherten Ort zu jedem Zeitpunkt berechnet, ob er geöffnet oder geschlossen ist, wann er schließt und wann er das nächste Mal öffnet. Vollständig unit-getestet.

---

## Eingaben

- `lib/models/location.dart`, `lib/models/opening_day.dart` aus P02
- `1.1-spezifikation.md` → Zustandslogik "Jetzt geöffnet?", Mittagspause-Logik
- `1.2-plan.md` → Logik-Skelett (Pseudocode für `isOpenNow`, `findNextOpening`, `buildWidgetData`)

---

## Aufgaben

1. **`OpenStatus`-Klasse anlegen** (`lib/models/open_status.dart`)
   - `offen` (bool)
   - `schliesstUm` (TimeOfDay?) — wenn geöffnet: Schließzeit
   - `naechsteOeffnung` (NextOpening?) — wenn geschlossen: nächster Öffnungszeitpunkt
   - `NextOpening`-Klasse: `wochentag` (Wochentag), `von` (TimeOfDay), `istHeute` (bool)

2. **`OpenStatusService` implementieren** (`lib/services/open_status_service.dart`)

   **Methode `isOpenNow(Location location, DateTime now) → OpenStatus`:** (E9 — Block-Logik)
   - Aktuellen Wochentag aus `now` bestimmen, `OpeningDay` für diesen Tag suchen
   - Wenn nicht gefunden oder `zeiten` leer: geschlossen, `findNextOpening` aufrufen
   - **Wenn aktuelle Zeit in irgendeinem Block (`von ≤ jetzt < bis`): geöffnet, `schliesstUm = bis` dieses Blocks**
   - Sonst geschlossen: gibt es heute einen späteren Block (z.B. nach einer Pause), ist das die nächste Öffnung; andernfalls `findNextOpening`
   - Pause = Lücke zwischen zwei Blöcken (kein eigenes Feld mehr)

   **Methode `naechsteAenderung(List<Location> locations, DateTime now) → DateTime?`:** (E16)
   - Kleinste echt-zukünftige Block-Grenze (`von`/`bis`) über alle Einträge, sonst nächste Mitternacht
   - Liefert den Zeitpunkt, zu dem App-Timer bzw. Widget-`AlarmManager` neu rechnen sollen

   **Methode `findNextOpening(Location location, DateTime now) → NextOpening?`:**
   - Sucht in den nächsten 7 Tagen (heute + 1 bis heute + 7) den nächsten Tag mit `geoeffnet == true`
   - Gibt `NextOpening` mit korrektem Wochentag, Öffnungszeit und `istHeute = false` zurück
   - Wenn kein Tag gefunden: `null` (Ort ist nie geöffnet — Sonderfall)
   - Hinweis: "heute aber nach aktueller Zeit" ebenfalls berücksichtigen wenn `bis` noch nicht überschritten (nach Mittagspause)

   **Methode `buildWidgetData(List<Location> locations, DateTime now) → WidgetData`:**
   - Ruft `isOpenNow` für jede Location auf
   - Teilt in `geoeffnet` und `geschlossen` auf
   - Sortiert beide Listen alphabetisch nach `name`
   - Gibt `WidgetData`-Objekt zurück (neue Klasse: `geoeffnet: List<WidgetEntry>`, `geschlossen: List<WidgetEntry>`)
   - `WidgetEntry`: `id`, `name`, `statusText` (z.B. "bis 18:00" oder "ab Mo 09:00" oder "heute geschlossen")

3. **`statusText`-Hilfsmethode** (als Methode auf `OpenStatus` oder in Service)
   - Geöffnet: `"bis HH:MM"`
   - Mittagspause: `"Pause bis HH:MM"`
   - Heute später geöffnet: `"ab HH:MM"`
   - Morgen: `"morgen ab HH:MM"`
   - Anderer Tag: `"[Tagname] ab HH:MM"`
   - Nie geöffnet / null: `"Keine Öffnungszeiten"`
   - Alle Strings über ARB-Datei (`lib/l10n/app_de.arb`) — kein Hardcoded-Text

4. **Unit-Tests schreiben** (`test/services/open_status_service_test.dart`)

   Pflicht-Testfälle:
   - Normaler Werktag, aktuell geöffnet → `offen: true`, korrekte Schließzeit
   - Normaler Werktag, vor Öffnungszeit → `offen: false`, `naechsteOeffnung` = heute
   - Normaler Werktag, nach Schließzeit → `offen: false`, `naechsteOeffnung` = nächster Öffnungstag
   - Zeit in einer Pause (zwischen zwei Blöcken) → `offen: false`, `naechsteOeffnung` = `von` des nächsten Blocks heute
   - **Mehrblock-Tag (z.B. 3 Blöcke mit 2 Pausen): jeder Block korrekt offen, jede Lücke geschlossen**
   - `naechsteAenderung`: liefert die nächste Block-Grenze (inkl. Mitternacht-Fall)
   - Sonntag, nächster Öffnungstag ist Montag → Wochengrenze korrekt
   - Samstag 23:59, nächste Öffnung Montag → überspringt Sonntag korrekt
   - Ort hat keinen Eintrag für aktuellen Tag → geschlossen
   - Ort ist an keinem Tag geöffnet → `findNextOpening` gibt `null` zurück
   - `buildWidgetData` mit 3 Orten (2 offen, 1 geschlossen) → korrekte Aufteilung und Sortierung

---

## Lieferobjekt

- `lib/models/open_status.dart` (inkl. `NextOpening`, `WidgetData`, `WidgetEntry`)
- `lib/services/open_status_service.dart`
- `lib/l10n/app_de.arb` — ergänzt um alle Status-Strings
- `test/services/open_status_service_test.dart` — alle Testfälle grün

---

## Akzeptanzkriterien

- [ ] `flutter test test/services/open_status_service_test.dart` — alle Tests grün
- [ ] Wochengrenze (Sonntag → Montag) wird korrekt behandelt
- [ ] Mittagspause: während der Pause → geschlossen, danach → geöffnet
- [ ] Ort ohne einzigen geöffneten Tag → kein Crash, `null` zurückgegeben
- [ ] `statusText` enthält keinen hardcodierten deutschen String (alles via ARB)
- [ ] `flutter analyze` gibt keine Fehler aus

---

## Hinweise

- `DateTime.now()` niemals direkt im Service aufrufen — immer als Parameter übergeben. Das macht die Testbarkeit erst möglich (Testfälle können beliebige Zeitpunkte simulieren).
- Wochentag-Mapping: Dart `DateTime.weekday` liefert 1 (Montag) bis 7 (Sonntag) — muss auf `Wochentag`-Enum gemappt werden
- Die Mittagspause-Logik ist der kniffligste Teil: nach der Pause ist der Ort wieder geöffnet — `findNextOpening` darf heute nicht überspringen wenn `pauseBis` noch in der Zukunft liegt
- `buildWidgetData` wird später vom Android Widget aufgerufen — das Widget läuft in einem separaten Prozess und kann keinen Riverpod-State nutzen. Der Service muss daher zustandslos sein (pure function, kein Singleton-State).
