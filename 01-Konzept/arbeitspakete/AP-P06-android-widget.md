# Arbeitspaket

## AP-P06 — Android Widget

| Feld | Wert |
|---|---|
| **Plan-ID** | P06 |
| **Spec-Referenz** | Workflow 2 (Tagesübersicht im Widget), Nicht-funktionale Anforderungen (Performance) |
| **Komponente** | Android Widget |
| **Agent** | Georg |
| **Geschätzte Größe** | ~800 LOC · ~120K Tokens |
| **Abhängig von** | P03, P04, P05 |
| **Übergabe an** | P09 |

> ⚠️ **Aktualisiert 2026-06-10 (E10, E14, E16):** **Fester Filter pro Widget**, beim Platzieren via **Widget-Konfigurations-Activity** gewählt; **kein „WhenOpen"-Schriftzug** (Kopf: Kategorie links / Datum rechts); bei einer Kategorie flache Liste, bei „Alle Orte" nach Kategorie gruppiert; mehrere Widget-Instanzen möglich. **Aktualisierung nach E16** (AlarmManager auf nächste Grenze + WorkManager-Netz, kein „schließt bald"). Maßgeblich: AP-Zeile in [`../1.3-scope-entscheidungen.md`](../1.3-scope-entscheidungen.md).

---

## Ziel

Einen Android App Widget implementieren, der auf einem dedizierten Homescreen-Screen die Tagesansicht aller gespeicherten Orte zeigt — oben die geöffneten, unten die geschlossenen. Tippen auf einen Eintrag öffnet die App direkt in der Detailansicht dieses Eintrags.

---

## Eingaben

- `lib/models/open_status.dart` aus P03 (`WidgetData`, `WidgetEntry`)
- `lib/services/open_status_service.dart` aus P03 (`buildWidgetData`)
- `lib/repositories/location_repository.dart` aus P02
- Vollständige App aus P04 + P05 (für Deep-Link-Test)
- `1.1-spezifikation.md` → Workflow 2, Nicht-funktionale Anforderungen (Widget lädt ohne Verzögerung)

---

## Aufgaben

1. **`home_widget` Package + Konfigurations-Activity** (E14)
   - `AndroidManifest.xml`: Widget-Provider registrieren; **`android:configure`** auf eine Konfig-Activity setzen
   - App Group ID einrichten (Shared Storage App ↔ Widget)
   - `when_open_widget_info.xml` (Metadaten) + `when_open_widget.xml` (Layout)
   - **Konfigurations-Activity:** beim Platzieren Kategorie wählen lassen (nur falls Kategorien existieren, sonst „Alle Orte"); gewählte Kategorie-ID je `appWidgetId` speichern. Mehrere Instanzen = je eigener Filter.

2. **Android Widget-Layout** (`when_open_widget.xml`) — **E10, E14**
   - `RemoteViews`-basiertes Layout (Android-Anforderung)
   - **Kopf: Kategorie-Name links, Datum rechts — kein „WhenOpen"-Schriftzug**
   - **Inhalt gefiltert auf die Widget-Kategorie:** flache Liste (Name + Statustext, offen grün / geschlossen grau); bei „Alle Orte" zusätzlich Kategorie-Überschriften
   - Jede Zeile tippbar (PendingIntent mit Deep Link)
   - Leerzustand: "Keine Einträge gespeichert — tippe hier um zu starten"

3. **Widget-Datenprovider in Dart** (`lib/widget/widget_data_provider.dart`)
   - Funktion `updateWidget()`: liest alle Locations aus Repository, ruft `buildWidgetData(locations, DateTime.now())` auf, schreibt Ergebnis in AppGroup-SharedPreferences via `home_widget`
   - Wird aufgerufen nach: jedem Save, Update, Delete in `LocationsProvider` + beim App-Start

4. **Widget-Background-Callback** (`lib/widget/widget_background_callback.dart`)
   - `@pragma('vm:entry-point')` Flutter-Einstiegspunkt für Widget-Updates
   - Android ruft diesen Callback auf wenn Widget aktualisiert werden soll (z.B. Mitternacht-Update, Systemereignis)
   - Liest JSON-Datei, berechnet Status, schreibt in AppGroup, löst Widget-Redraw aus

5. **Deep-Link-Integration**
   - Tippen auf Widget-Eintrag → PendingIntent sendet Intent mit URI `whenopen://open/[id]`
   - go_router-Route `/open/:id` in `app.dart` (aus P01 bereits als Platzhalter vorhanden) → navigiert zu `DetailScreen` mit dieser ID
   - Wenn App nicht läuft: App startet und öffnet direkt DetailScreen
   - Wenn App läuft: direkt zu DetailScreen navigieren (kein doppelter Startscreen)

6. **Automatisches Update konfigurieren (E16 — kein Polling)**
   - **Ereignisgetrieben:** nach jedem Save/Update/Delete + wenn die App in den Hintergrund geht (`AppLifecycleListener`) → Widget-Daten schreiben + Redraw
   - **Grenzgenau:** `AlarmManager`-Alarm exakt auf `naechsteAenderung(now)` (nächste Block-Grenze, inkl. Mitternacht); Callback rechnet neu, zeichnet neu, plant den **nächsten** Alarm (self-rescheduling)
   - **Sicherheitsnetz:** `WorkManager` periodisch ~15 min (robuster/Doze-bewusster als `updatePeriodMillis`)
   - Auf `TIME_CHANGED`/`TIMEZONE_CHANGED` reagieren → neu rechnen + Alarm neu setzen
   - Hinweis: exakte Alarme auf Android 12+ ggf. `setExactAndAllowWhileIdle`/Berechtigung; `USER_PRESENT` ist für Manifest-Receiver gesperrt → Entsperr-Frische kommt über den App-Lifecycle

7. **Manueller Test auf echtem Gerät**
   - Widget auf Homescreen platzieren
   - Eintrag in App hinzufügen → Widget aktualisiert sich
   - Statuswechsel um Mitternacht simulieren (Systemzeit vordrehen)
   - Tippen auf Eintrag → App öffnet Detailansicht

---

## Lieferobjekt

- `android/app/src/main/res/xml/when_open_widget_info.xml`
- `android/app/src/main/res/layout/when_open_widget.xml`
- `android/app/src/main/AndroidManifest.xml` (ergänzt)
- `lib/widget/widget_data_provider.dart`
- `lib/widget/widget_background_callback.dart`
- Deep-Link-Route in `app.dart` aktiviert

---

## Akzeptanzkriterien

- [ ] Widget lässt sich auf Android-Homescreen platzieren
- [ ] Widget zeigt korrekte Tagesansicht (offen oben, geschlossen unten)
- [ ] Widget aktualisiert sich nach Eintrag hinzufügen/bearbeiten/löschen in der App
- [ ] Tippen auf Widget-Eintrag öffnet korrekte Detailansicht in der App
- [ ] App startet direkt in Detailansicht wenn sie vorher nicht lief (Cold Start)
- [ ] Widget zeigt Leerzustand wenn keine Einträge vorhanden
- [ ] Keine spürbare Verzögerung beim Entsperren des Geräts

---

## UX-Constraint

- **Zielnutzer:** Alltagsnutzer ohne technisches Wissen
- **Widget ist der Hauptzugang zur App** — es muss auf einen Blick lesbar sein ohne hineinzoomen zu müssen
- **Nicht exponieren:** interne IDs, technische Statuscodes, Fehlerdetails
- **Statustext im Widget:** kurz und klar — "bis 18:00" statt "Schließt um 18:00 Uhr", "ab Mo" statt "Nächste Öffnung: Montag"
- **Leerzustand:** motivierend formulieren — "Tippe hier um deinen ersten Ort hinzuzufügen" statt leeres Widget

---

## Hinweise

- Android Widgets laufen in einem separaten Prozess — kein Zugriff auf Flutter-Riverpod-State. Der `widget_background_callback` muss die JSON-Datei direkt lesen, nicht über Provider
- `home_widget` Package vereinfacht die Dart↔Android-Kommunikation erheblich — Dokumentation gründlich lesen vor Implementierung: https://pub.dev/packages/home_widget
- Widget-Layouts sind Android XML (`RemoteViews`) — kein Flutter-Widget. Das ist der technisch ungewohnteste Teil dieses Pakets
- Testbarkeit: Widget-Logik (Datenaufbereitung) ist in `widget_data_provider.dart` isoliert — dieser kann unit-getestet werden. Das Android-Rendering selbst nur manuell testbar
- Proof-of-Concept empfohlen: ein minimales Widget ("Hello World") als erstes bauen bevor das vollständige Layout implementiert wird
