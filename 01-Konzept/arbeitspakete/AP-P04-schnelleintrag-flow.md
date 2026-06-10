# Arbeitspaket

## AP-P04 — Schnelleintrag-Flow

| Feld | Wert |
|---|---|
| **Plan-ID** | P04 |
| **Spec-Referenz** | Workflow 1 (Schnelleintrag), Edge Cases, Validierung |
| **Komponente** | UI-Layer + Business-Logic |
| **Agent** | Georg |
| **Geschätzte Größe** | ~1.200 LOC · ~180K Tokens |
| **Abhängig von** | P02, P03 |
| **Übergabe an** | P06, P08b |

> ⚠️ **Aktualisiert 2026-06-10 (E9, E15):** Tagesschritt erfasst **mehrere Zeitblöcke** („＋ weiterer Zeitblock") statt eines festen Mittagspausen-Toggles. **Neuer Schritt „Kategorie"** (Chips + „Neue Kategorie"-Dialog mit Name/Farbe) → Flow **9 → 10 Schritte**. Maßgeblich: AP-Zeile in [`../1.3-scope-entscheidungen.md`](../1.3-scope-entscheidungen.md).

---

## Ziel

Den sequenziellen Schnelleintrag-Dialog implementieren — sieben Tagesschritte (Mo–So) mit Vorschlagswerten, Zeitpicker, Mittagspause und Validierung. Am Ende wird ein vollständiges `Location`-Objekt gespeichert.

---

## Eingaben

- `lib/models/` aus P02 (`Location`, `OpeningDay`, `Wochentag`)
- `lib/repositories/location_repository.dart` aus P02
- `lib/providers/locations_provider.dart` aus P02
- `1.1-spezifikation.md` → Workflow 1 (Schnelleintrag), Validierungsregeln, Edge Cases

---

## Aufgaben

1. **`ValidationService` implementieren** (`lib/services/validation_service.dart`)
   - `validateLocation(Location location) → List<ValidationError>`
   - Prüft: Name nicht leer, mindestens 1 Tag mit `geoeffnet = true`
   - Prüft pro Tag: `von` < `bis`, wenn `pauseVon` gesetzt dann `pauseBis` auch gesetzt und `pauseVon` < `pauseBis` und Pause liegt innerhalb `von`–`bis`
   - `ValidationError`: `feld` (String), `meldung` (String aus ARB)

2. **State-Klasse für den Flow** (`lib/screens/quick_entry/quick_entry_state.dart`)
   - Hält: `name`, `adresse?`, `telefon?`, `googleMapsLink?`, `oeffnungszeiten` (Map\<Wochentag, OpeningDay\>), `aktuellerSchritt` (0 = Name, 1–7 = Mo–So, 8 = Optionale Felder)
   - `letzterGueltigerTag`: der zuletzt eingetragene `OpeningDay` mit `geoeffnet = true` — wird als Vorschlag für den nächsten Tag verwendet

3. **`QuickEntryScreen` implementieren** (`lib/screens/quick_entry/quick_entry_screen.dart`)
   - Steuert den Ablauf: welcher Schritt ist aktiv, Vor/Zurück-Navigation
   - Fortschrittsanzeige (z.B. Schrittindikator "Schritt 3 von 9")
   - FAB oder Button "Weiter" / "Speichern"
   - Validierung beim Speichern, Fehlermeldung anzeigen
   - Bei Erfolg: `LocationsProvider.add(location)` aufrufen, zurück zur Hauptliste

4. **`NameStep`-Widget** (`lib/screens/quick_entry/name_step.dart`)
   - Textfeld für Name (Pflicht, Autofokus)
   - Hinweis: "Name des Orts, z. B. Kinderarzt Müller"

5. **`DayEntryStep`-Widget** (`lib/screens/quick_entry/day_entry_step.dart`)
   - Zeigt Wochentag-Name oben (aus ARB: "Montag", "Dienstag" etc.)
   - Drei Optionen als Buttons/Chips:
     - "Geöffnet" → Zeitpicker-Bereich einblenden
     - "Wie vorheriger Tag" (nur aktiv wenn `letzterGueltigerTag != null`) → Vorschlag übernehmen
     - "Geschlossen" → Tag als geschlossen markieren
   - Zeitblock-Bereich (sichtbar wenn "Geöffnet" gewählt) — **E9**:
     - Pro Block: "Öffnet um" / "Schließt um" → je `TimePickerDialog` (24h)
     - **"＋ weiterer Zeitblock"** fügt einen Block hinzu; jeder Block einzeln löschbar (✕)
     - Die Lücke zwischen zwei Blöcken ist automatisch die Pause (kein eigener Pausen-Toggle mehr)
   - Vorschlag (Blöcke des letzten geöffneten Tags) wird vorausgefüllt wenn `letzterGueltigerTag != null`

6b. **`KategorieStep`-Widget** (`lib/screens/quick_entry/kategorie_step.dart`) — **E15, neuer Schritt 9/10**
   - Vorhandene Kategorien als Chips; „＋ Neue Kategorie" öffnet Dialog (Name + Farbe), legt an und wählt aus
   - Ohne Auswahl → Eintrag landet unter „Sonstige"; Flow hat damit **10 Schritte** (Name · Mo–So · Kategorie · Zusatzinfos)

6. **`OptionalFieldsStep`-Widget** (`lib/screens/quick_entry/optional_fields_step.dart`)
   - Textfelder für Adresse, Telefonnummer, Google Maps Link (alle optional)
   - Google Maps Link: einfache URL-Validierung (beginnt mit `https://`)
   - Hinweis: "Diese Felder sind optional. Du kannst sie später ergänzen."

7. **Unit-Tests für ValidationService** (`test/services/validation_service_test.dart`)
   - Kein Name → Fehler
   - Kein geöffneter Tag → Fehler
   - `von` nach `bis` → Fehler
   - Pause außerhalb der Öffnungszeiten → Fehler
   - Valide Location → keine Fehler

---

## Lieferobjekt

- `lib/services/validation_service.dart`
- `lib/screens/quick_entry/quick_entry_screen.dart`
- `lib/screens/quick_entry/quick_entry_state.dart`
- `lib/screens/quick_entry/name_step.dart`
- `lib/screens/quick_entry/day_entry_step.dart`
- `lib/screens/quick_entry/optional_fields_step.dart`
- `lib/l10n/app_de.arb` — ergänzt um alle Strings dieses Flows
- `test/services/validation_service_test.dart`

---

## Akzeptanzkriterien

- [ ] Neuer Eintrag kann vollständig von Name bis Speichern durchlaufen werden
- [ ] Vorschlagswert des vorherigen Tags wird korrekt angeboten
- [ ] "Wie vorheriger Tag" ist deaktiviert wenn noch kein Tag eingetragen wurde
- [ ] Speichern ohne Name → Fehlermeldung, kein Speichern
- [ ] Speichern ohne einen geöffneten Tag → Fehlermeldung, kein Speichern
- [ ] Gespeicherter Eintrag erscheint danach in der Hauptliste (Riverpod-State aktualisiert)
- [ ] `flutter test test/services/validation_service_test.dart` — alle Tests grün
- [ ] Kein hardcodierter Text — alles via `app_de.arb`

---

## UX-Constraint

- **Zielnutzer:** Endnutzer ohne technisches Wissen (Mutter, Sozialarbeiter, Alltagsbürger)
- **Nicht exponieren:** Interne Feldnamen (`pauseVon`, `pauseBis`, `geoeffnet`) — der Nutzer sieht "Mittagspause", "Geöffnet", "Geschlossen"
- **Wie der Nutzer es beschreibt:** "Ich trage ein, wann der Laden aufmacht und zumacht"
- **Zeitpicker:** Flutter's `showTimePicker` in 24h-Format verwenden (kein AM/PM für deutschsprachige Nutzer)
- **Schrittzahl sichtbar halten:** Nutzer muss wissen, wie weit er noch ist. "Montag — Schritt 2 von 9" ist besser als "Montag" allein.

---

## Hinweise

- `DayEntryStep` wird 7-mal instanziiert (Mo–So) — als generisches Widget bauen, das den `Wochentag` als Parameter bekommt
- Vorschlagswert-Logik: der letzte Tag mit `geoeffnet = true` ist der Vorschlag, nicht der unmittelbar vorherige Tag. Beispiel: Mo geöffnet, Di geschlossen, Mi → Vorschlag ist Mo
- Der Bearbeiten-Flow (aus P05) verwendet dieselben Widgets — darauf achten, dass `DayEntryStep` und `OptionalFieldsStep` auch mit vorausgefüllten Werten funktionieren
- "Wie vorheriger Tag"-Button sprachlich prüfen: könnte auch "Gleiche Zeiten" heißen — was verständlicher ist für Nutzer ohne technischen Hintergrund
