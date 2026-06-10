# Arbeitspaket

## AP-P05 — Hauptliste und Detailansicht

| Feld | Wert |
|---|---|
| **Plan-ID** | P05 |
| **Spec-Referenz** | Workflow 2 (Tagesübersicht), Workflow 3 (Hauptliste), Workflow 4 (Detailansicht) |
| **Komponente** | UI-Layer |
| **Agent** | Georg |
| **Geschätzte Größe** | ~1.200 LOC · ~180K Tokens |
| **Abhängig von** | P02, P03 |
| **Übergabe an** | P06, P07 |

> ⚠️ **Aktualisiert 2026-06-10 (E9–E15):** Liste **nach Kategorie gruppiert**; Umschalten über **Bottom-Umschalter + Auswahl-Sheet (Google-Tasks-Stil)** + Wischen (kein Chip-Streifen). Detail zeigt **Mehrblock-Zeiten**. **Löschen mit „Rückgängig"-SnackBar** (E13). **Limit 50** statt 10 (E11). Neu: **„Kategorien verwalten"-Screen** (E15) + **Schnell-Umhängen per Lang-Tippen**. Maßgeblich: AP-Zeile in [`../1.3-scope-entscheidungen.md`](../1.3-scope-entscheidungen.md).

---

## Ziel

Den `HomeScreen` (alphabetische Liste aller Einträge mit aktuellem Status) und den `DetailScreen` (Wochenübersicht eines Eintrags mit allen Aktionen) implementieren, inklusive Bearbeiten- und Löschen-Flow.

---

## Eingaben

- `lib/models/` aus P02
- `lib/providers/locations_provider.dart` aus P02
- `lib/services/open_status_service.dart` aus P03
- Platzhalter-Screens aus P01 (werden ersetzt)
- `1.1-spezifikation.md` → Workflow 3 und 4, Edge Cases (Löschen mit Bestätigung)

---

## Aufgaben

1. **`HomeScreen` implementieren** (`lib/screens/home_screen.dart`) — **E10**
   - Liest alle Locations aus `locationsProvider`
   - **Gruppiert nach Kategorie** (Reihenfolge aus `Kategorie.sortierung`), innerhalb alphabetisch; „Sonstige" zuletzt
   - **Bottom-Umschalter (Google-Tasks-Stil):** unten links aktuelle Ansicht („Alle Orte ⌃") → öffnet **Auswahl-Sheet** (Alle Orte + Kategorien mit Anzahl + „＋ Neue Kategorie" + „Kategorien verwalten")
   - **Wischen** links/rechts blättert zwischen Ansichten (Alle / je Kategorie); bei einer Kategorie flache Liste, bei „Alle" gruppiert
   - Leerzustand: "Noch keine Einträge. Tippe auf + um zu starten." (kein leeres Weiß)
   - **„＋" unten rechts** → `/quick-entry`, im aktiven Filter vorbelegt
   - `AppBar` mit App-Name "WhenOpen" + Such-Icon

2. **`LocationListTile`-Widget** (`lib/widgets/location_list_tile.dart`)
   - Zeigt: Name (fett), Statustext (z.B. "bis 18:00" oder "ab Mo 09:00")
   - Status-Badge: grüner Punkt wenn geöffnet, grauer Punkt wenn geschlossen
   - Tippen → navigiert zu `/detail/:id`
   - Status wird live berechnet via `OpenStatusService.isOpenNow(location, DateTime.now())`
   - Kein manuelles Aktualisieren nötig: Riverpod rebuilt automatisch bei Datenänderung

3. **`DetailScreen` implementieren** (`lib/screens/detail_screen.dart`)
   - Empfängt `id` als Route-Parameter, lädt Location aus `locationsProvider`
   - **Wochenübersicht:** 7 Zeilen (Mo–So), je Zeile: Tagesname + Öffnungszeiten oder "Geschlossen"
   - Hervorhebung des aktuellen Tages (fetter Text oder farbiger Hintergrund)
   - Mittagspause anzeigen falls vorhanden: z.B. "09:00–12:00, 13:00–18:00"
   - **Optionale Felder** (nur anzeigen wenn befüllt):
     - Adresse: Text, tippbar → öffnet Karten-App via URL (P07 liefert diese Funktion)
     - Telefon: Text, tippbar → öffnet Telefonwähler (`tel:`-URL-Scheme)
     - Google Maps Link: Button "In Google Maps öffnen" (P07 liefert diese Funktion)
   - **Aktionsleiste** (unten oder als AppBar-Menü):
     - "Bearbeiten" → Bearbeiten-Flow
     - "Löschen" → Bestätigungsdialog

4. **Bearbeiten-Flow** (Wiederverwendung von P04-Widgets)
   - Navigiert zu `/quick-entry?editId=[id]` (oder separater Route)
   - `QuickEntryScreen` erkennt `editId` und lädt vorhandene Location vor
   - Alle P04-Widgets müssen mit vorausgefüllten Werten funktionieren
   - Speichern ruft `LocationsProvider.update(location)` auf statt `add`

5. **Löschen-Flow (E13 — mit Undo)**
   - Direkt löschen (ohne Vorab-Dialog) + `SnackBar` "[Name] gelöscht" mit Aktion **„Rückgängig"** (~5 s)
   - Innerhalb der Frist: Eintrag wiederherstellen; nach Ablauf: `LocationsProvider.delete(id)` endgültig
   - Implementierung: Eintrag zunächst aus der sichtbaren Liste entfernen, erst nach Timeout persistent löschen

6. **Kategorie-Verwaltung & Schnell-Umhängen (E15)**
   - **`KategorienScreen`** (`lib/screens/kategorien_screen.dart`, aus Einstellungen): Liste aller Kategorien mit Farbe + Anzahl; pro Kategorie Menü **Umbenennen / Farbe / Zusammenführen / Löschen**; Drag-Sortierung; „Sonstige" nicht löschbar (Löschen → Einträge auf „Sonstige", mit Vorwarnung „N Orte betroffen")
   - **Schnell-Umhängen:** Lang-Tippen auf einen Listeneintrag → Bottom-Sheet „Kategorie ändern" (Kategorien + „＋ Neue Kategorie")

7. **50-Einträge-Hinweis (E11)**
   - FAB bleibt **immer aktiv** (kein harter Block)
   - Bei `locations.length >= 50` beim Speichern weicher Hinweis: „Maximale Anzahl von 50 Einträgen erreicht."

---

## Lieferobjekt

- `lib/screens/home_screen.dart`
- `lib/screens/detail_screen.dart`
- `lib/widgets/location_list_tile.dart`
- `lib/l10n/app_de.arb` — ergänzt um alle Strings dieser Screens
- Bearbeiten-Flow in `QuickEntryScreen` aktiviert (editId-Parameter)

---

## Akzeptanzkriterien

- [ ] Hauptliste zeigt alle gespeicherten Einträge alphabetisch
- [ ] Jeder Eintrag zeigt korrekten aktuellen Status (offen/geschlossen)
- [ ] Leerzustand zeigt hilfreichen Text statt leerer Seite
- [ ] Detailansicht zeigt korrekte Wochenübersicht inkl. Mittagspausen
- [ ] Aktueller Wochentag ist in der Detailansicht hervorgehoben
- [ ] Löschen öffnet Bestätigungsdialog — kein direktes Löschen ohne Bestätigung
- [ ] Nach dem Löschen erscheint SnackBar mit Name des gelöschten Eintrags
- [ ] Bei 10 Einträgen ist FAB deaktiviert mit erklärendem SnackBar
- [ ] Bearbeiten lädt bestehende Werte vor — kein leeres Formular
- [ ] Kein hardcodierter Text — alles via `app_de.arb`

---

## UX-Constraint

- **Zielnutzer:** Endnutzer ohne technisches Wissen
- **Statusanzeige:** Nutzer versteht "bis 18:00" und "ab Mo 09:00" — keine technischen Status-Codes
- **Mittagspause-Darstellung:** "09:00–12:00 · 13:00–18:00" ist verständlicher als "Öffnet: 09:00, Schließt: 18:00, Pause: 12:00–13:00"
- **Löschen:** Der Name im Bestätigungsdialog und in der SnackBar hilft dem Nutzer zu erkennen, was er getan hat — besonders wichtig bei versehentlichem Tippen
- **Hervorhebung des aktuellen Tags:** Nutzer sieht auf einen Blick "Das ist heute" — subtil, nicht aufdringlich (kein Fett+Farbe+Icon gleichzeitig)

---

## Hinweise

- `DetailScreen` lädt die Location via ID aus dem Provider — wenn die ID nicht existiert (gelöschter Eintrag, Deep Link veraltet): zurück zur Hauptliste navigieren und SnackBar "Eintrag nicht gefunden"
- Telefonnummer: `url_launcher` Package für `tel:`-URL-Scheme benötigt — als Dependency ergänzen falls nicht vorhanden, alternativ koordinieren mit P07 (der ohnehin URL-Launching implementiert)
- Der Bearbeiten-Flow teilt Code mit P04 — sicherstellen dass P04-Widgets den `editId`-Parameter verstehen, bevor P05 abgeschlossen ist
