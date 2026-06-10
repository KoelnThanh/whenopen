# Arbeitspaket

## AP-P08b — OSM-Import-Assistent

| Feld | Wert |
|---|---|
| **Plan-ID** | P08b |
| **Spec-Referenz** | Workflow 5 (Import-Assistent), Integrationen (OSM/Nominatim), Edge Cases (Import fehlgeschlagen) |
| **Komponente** | Import-Modul |
| **Agent** | Georg |
| **Geschätzte Größe** | ~600 LOC · ~90K Tokens |
| **Abhängig von** | P04 |
| **Übergabe an** | P06, P09 |

> ⚠️ **Aktualisiert 2026-06-10 (E9):** Der OSM-`opening_hours`-Parser erzeugt **Zeitblöcke** (`zeiten: [{von,bis}]`) pro Tag — passt gut, da das OSM-Format ohnehin blockbasiert ist (z.B. „Mo-Fr 09:00-12:00,14:00-18:00" → zwei Blöcke). Import kann optional auch eine **Kategorie** vorschlagen (E15). Maßgeblich: AP-Zeile in [`../1.3-scope-entscheidungen.md`](../1.3-scope-entscheidungen.md).

---

## Ziel

Einen optionalen OSM-Import-Assistenten in den Schnelleintrag-Flow einbauen: Nutzer sucht nach einem Ort, wählt aus Trefferliste und bekommt verfügbare Felder vorbelegt. Alle Daten werden vor dem Speichern zur Bestätigung angezeigt. Der manuelle Eintrag bleibt immer der primäre Weg.

---

## Eingaben

- `lib/screens/quick_entry/` aus P04 (Schnelleintrag-Flow — wird um Suchschritt ergänzt)
- `lib/models/` aus P02
- `1.1-spezifikation.md` → Workflow 5 (Import-Assistent), Entscheidung E2 (OSM/Nominatim)
- OSM Nominatim API Dokumentation: https://nominatim.openstreetmap.org/ui/search.html

---

## Aufgaben

1. **`NominatimService` implementieren** (`lib/services/nominatim_service.dart`)

   **`searchPlaces(String query) → Future<List<NominatimResult>>`**
   - HTTP GET: `https://nominatim.openstreetmap.org/search?q=[query]&format=json&extratags=1&addressdetails=1&limit=5`
   - Header: `User-Agent: WhenOpen/1.0 (contact: [deine E-Mail])` — Nominatim-Pflicht
   - Parst Antwort zu `NominatimResult`-Objekten
   - Fehlerbehandlung: Netzwerkfehler, leere Ergebnisse, Timeout (5 Sekunden)

   **`NominatimResult`-Klasse:**
   - `displayName` (String) — vollständiger Name für Anzeige
   - `name` (String) — kurzer Name (aus `namedetails.name` oder erster Teil von `displayName`)
   - `adresse` (String?) — aus `address`-Objekt zusammengebaut
   - `telefon` (String?) — aus `extratags.phone`
   - `oeffnungszeiten` (String?) — aus `extratags.opening_hours` (Rohwert, noch nicht geparsed)

2. **`OpeningHoursParser` implementieren** (`lib/services/opening_hours_parser.dart`)
   - Parst OSM `opening_hours`-Format in `List<OpeningDay>`
   - **Unterstützte Formate** (die häufigsten ~80% der Fälle):
     - `Mo-Fr 09:00-18:00` → Mo bis Fr geöffnet 9–18
     - `Mo-Fr 09:00-18:00; Sa 10:00-14:00` → Wochentage + Samstag
     - `Mo-Sa 09:00-20:00; Su off` → Mo–Sa geöffnet, Sonntag geschlossen
     - `09:00-18:00` (ohne Wochentag) → alle Tage geöffnet
     - `Mo-Fr 09:00-12:00,14:00-18:00` → Mittagspause erkannt
   - **Nicht unterstützte Formate** → `null` zurückgeben (Nutzer trägt manuell ein)
   - Unit-getestet mit den obigen Formaten

3. **Suchschritt in Schnelleintrag-Flow einbauen** (`lib/screens/quick_entry/`)
   - Neuer optionaler Einstieg vor dem Name-Schritt: `OsmSearchStep`
   - "Ort aus OpenStreetMap suchen" als optionaler Button auf dem Startscreen des Schnelleintrags
   - Alternativer Weg: "Manuell eintragen" — springt direkt zu `NameStep`

4. **`OsmSearchStep`-Widget** (`lib/screens/quick_entry/osm_search_step.dart`)
   - Suchfeld mit Debounce (500ms) → ruft `NominatimService.searchPlaces` auf
   - Zeigt Ladeindikator während Suche läuft
   - Zeigt bis zu 5 Treffer als Liste (`displayName`)
   - Kein Netzwerk / Timeout / leere Ergebnisse: Hinweis "Keine Treffer — bitte manuell eintragen"
   - Tippen auf Treffer → `OsmConfirmStep`

5. **`OsmConfirmStep`-Widget** (`lib/screens/quick_entry/osm_confirm_step.dart`)
   - Zeigt alle verfügbaren Felder aus dem `NominatimResult` zur Bestätigung:
     - Name (bearbeitbar)
     - Adresse (bearbeitbar)
     - Telefon (bearbeitbar)
     - Öffnungszeiten: wenn Parser erfolgreich → Wochenübersicht anzeigen; wenn Parser fehlgeschlagen → "Öffnungszeiten nicht erkannt — bitte manuell eintragen"
   - Hinweis: "Daten aus OpenStreetMap — bitte auf Richtigkeit prüfen"
   - Button "Übernehmen" → befüllt Schnelleintrag-Flow mit diesen Daten, Nutzer kann weiter anpassen
   - Button "Manuell eintragen" → leerer Schnelleintrag-Flow

6. **Unit-Tests** (`test/services/opening_hours_parser_test.dart`)
   - Alle 5 unterstützten Formate aus Schritt 2
   - Unbekanntes Format → `null`
   - Leerer String → `null`

---

## Lieferobjekt

- `lib/services/nominatim_service.dart`
- `lib/models/nominatim_result.dart`
- `lib/services/opening_hours_parser.dart`
- `lib/screens/quick_entry/osm_search_step.dart`
- `lib/screens/quick_entry/osm_confirm_step.dart`
- `lib/l10n/app_de.arb` — Strings ergänzt
- `test/services/opening_hours_parser_test.dart`

---

## Akzeptanzkriterien

- [ ] Suche nach "Kinderarzt Köln" liefert Ergebnisse aus Nominatim
- [ ] Gefundene Felder werden im Bestätigungs-Screen angezeigt
- [ ] Nutzer kann alle Felder vor der Übernahme bearbeiten
- [ ] Parser erkennt die 5 häufigsten opening_hours-Formate korrekt
- [ ] Unbekanntes Format → Hinweis + manueller Eintrag, kein Crash
- [ ] Netzwerkfehler → Hinweis + manueller Eintrag, kein Crash
- [ ] Manueller Eintrag ist immer erreichbar (kein erzwungener OSM-Weg)
- [ ] `flutter test test/services/opening_hours_parser_test.dart` — alle Tests grün
- [ ] Kein hardcodierter Text — alles via `app_de.arb`

---

## UX-Constraint

- **Zielnutzer:** Alltagsnutzer ohne technisches Wissen
- **Nicht exponieren:** "OpenStreetMap", "Nominatim", "API", "extratags" — der Nutzer sieht "Ort suchen" und "Daten aus dem Web"
- **Hinweis auf Datenqualität:** klar aber nicht erschreckend formulieren — "Bitte prüfen, ob die Zeiten stimmen" statt "Datenqualität ca. 30%"
- **Import ist optional:** Der Nutzer darf nie das Gefühl haben, er muss zuerst suchen. "Manuell eintragen" ist gleichwertig prominent platziert

---

## Hinweise

- Nominatim Usage Policy: max. 1 Request/Sekunde, kein Scraping, User-Agent Pflicht — Debounce (500ms) und Limit=5 reichen für diese App
- OSM `opening_hours`-Format ist sehr komplex in der Vollform (eigene Spezifikation). Nur die häufigsten Fälle implementieren — edge cases landen im manuellen Korrekturdialog. Kein Vollparser anstreben.
- `extratags.opening_hours` ist in OSM-Daten selten vollständig — Datenqualität variiert stark nach Ort und Region. Das ist bekannt und akzeptiert.
- Das Import-Modul ist als austauschbares Interface konzipiert — `NominatimService` implementiert ein `ImportService`-Interface (einfaches Dart abstract class). Das erleichtert später den Austausch gegen HERE Maps oder andere Quellen.
- Google Places ToS-Risiko: vor Einsatz der Places API prüfen (developers.google.com/maps/terms, Abschnitt "Restrictions") — daher OSM gewählt. Entscheidung E2 in `1.1-spezifikation.md`.
