---
title: "Entscheidungsvorlage: Import-Weg Öffnungszeiten – WhenOpen App"
date: 2026-06-01
status: fertig
autor: Research-Agent (Claude Sonnet 4.6)
projekt: WhenOpen (Flutter Android Widget-App)
---

# Entscheidungsvorlage: Wie soll ein Nutzer Öffnungszeiten importieren?

## Kontext

WhenOpen ist eine Android Widget-App (Flutter), die Öffnungszeiten lokal speichert und als Widget anzeigt. Keine KI, keine Cloud, max. 10 Einträge pro Nutzer. Manueller Eintrag existiert bereits als Fallback. Gesucht sind komfortablere Import-Wege.

---

## Option A – Android Share-Intent aus Google Maps

### Was passiert beim Teilen aus Google Maps?

Wenn ein Nutzer in Google Maps auf "Teilen" tippt, sendet die App einen Standard-Android-`ACTION_SEND`-Intent mit `type = "text/plain"`. Der `EXTRA_TEXT`-Wert enthält ausschliesslich eine URL – keine strukturierten Daten, keine Öffnungszeiten.

**Typische geteilte URL-Formate:**
- Kurzlink: `https://maps.app.goo.gl/ABC123` (redirect)
- Vollständige Form nach Redirect: `https://www.google.com/maps/search/?api=1&query=Starbucks&query_place_id=ChIJsU30zM1qkFQRbnOm1_LBoG0`

Der `query_place_id`-Parameter (Google Place ID) ist oft – aber nicht immer – in der geteilten URL enthalten. Öffnungszeiten sind definitiv nicht Teil der geteilten URL.

### Technischer Ablauf für WhenOpen

Ein vollständiger Share-Intent-Workflow würde so aussehen:

1. App empfängt Share-Intent (Text/URL) via Flutter-Package
2. App parst die URL, extrahiert die Place ID (`ChIJ...`)
3. Falls Kurzlink: HTTP-Redirect folgen, um die vollständige URL zu erhalten
4. Mit der Place ID die Google Places API aufrufen und Öffnungszeiten abrufen
5. Nutzerin bestätigt/editiert und speichert lokal

**Wichtig:** Schritt 4 erfordert zwingend die Google Places API und erzeugt API-Kosten (→ Option B).

### Flutter-Implementierung

Das etablierteste Package ist `receive_sharing_intent` (v1.8.1, 73.800 Downloads, Apache-2.0, Pub.dev verified). Es empfängt Text/URL-Shares. Für den URL-Parse und API-Lookup muss die App selbst HTTP-Anfragen stellen.

### Bewertung Option A

| Kriterium | Bewertung |
|---|---|
| **Nutzer-Komfort** | Hoch – Nutzer kennt den "Teilen"-Button in Maps |
| **Datenqualität** | Nicht direkt – nur URL, kein strukturiertes Datum |
| **Machbarkeit** | Mittel – technisch lösbar, aber Abhängigkeit von Option B |
| **Kosten** | Verursacht Google Places API-Kosten (Schritt 4) |
| **Eigenständigkeit** | Nein – ist ein UX-Eingangskanal, kein Datenprovider |
| **ToS-Risiko** | Mittel – Place ID darf gecacht werden, Öffnungszeiten nicht (→ Option B ToS) |

**Fazit:** Option A ist kein eigenständiger Import-Weg, sondern ein UX-Kanal, der intern auf Option B zurückfällt. Machbar und komfortabel, aber ohne Option B wertlos.

---

## Option B – Google Places API

### Datenformat

Die Places API (New, 2025) liefert Öffnungszeiten in zwei Feldern:

- `regularOpeningHours`: Wöchentliche Regelzeiten (strukturierte `Period`-Objekte mit Wochentag, Uhrzeit als Integer-Felder)
- `currentOpeningHours`: Zeiten für die nächsten 7 Tage inkl. Sonderöffnungszeiten
- `weekdayDescriptions`: Menschenlesbare Strings (z.B. "Montag: 08:00–20:00")

**Beide Felder lösen das teurere "Place Details Enterprise"-SKU aus.**

### Kosten (Stand März 2025, verifiziert)

Google hat das Preismodell am 1. März 2025 grundlegend umgestellt: Das pauschale $200/Monat-Guthaben wurde durch SKU-individuelle Freikontingente ersetzt.

| SKU | Freikontingent/Monat | Preis über Kontingent |
|---|---|---|
| Place Details Essentials | 10.000 Events | $5,00 / 1.000 |
| Place Details Pro | 5.000 Events | $17,00 / 1.000 |
| **Place Details Enterprise** | **1.000 Events** | **$20,00 / 1.000** |

Öffnungszeiten (`regularOpeningHours`, `currentOpeningHours`) fallen unter **Place Details Enterprise**.

**Kostenrechnung für WhenOpen (<100 Anfragen/Tag = ~3.000/Monat):**
- 1.000 Anfragen sind kostenlos
- 2.000 Anfragen × $0,020 = **$40,00/Monat** – oder besser gesagt: bei 3.000 Anfragen/Monat liegt die monatliche Gebühr bei ca. $40.

**Aber:** Bei einer kleinen App mit 10 Einträgen pro Nutzer sind es pro Nutzer im Alltag eher 1–10 Lookups insgesamt (Erstimport). Bei 100 aktiven Nutzern mit je 5 Importen = 500 API-Calls – das liegt vollständig im Freikontingent.

**Realistisches MVP-Szenario (<1.000 Calls/Monat total): kostenlos.**

### Terms of Service – kritische Einschränkung

**Die Places API verbietet das lokale Cachen von Öffnungszeiten ausdrücklich:**

> "You must not pre-fetch, cache, or store Places API content beyond the allowed exceptions."

**Ausnahme:** Die Place ID (`ChIJ...`) darf unbegrenzt gespeichert werden.

Das ist ein fundamentaler Konflikt mit dem Kernkonzept von WhenOpen: Die App soll Öffnungszeiten lokal speichern. Würde die App Öffnungszeiten aus der Places API lokal ablegen (auch in einer SQLite-Datenbank), verletzt das die Google ToS – unabhängig von der Nutzerzahl.

Technisch könnten die Zeiten bei jedem Widget-Refresh neu abgerufen werden (nur Place ID speichern), aber das:
- Erfordert permanente Internetverbindung
- Kostet bei jedem Widget-Refresh API-Calls
- Widerspricht dem Designziel "lokal und offline"

### Flutter-Packages

- `flutter_google_places_sdk` (v0.4.3, nativer SDK-Wrapper, hat `OpeningHours`-Klasse)
- `google_place` (Dart API-Docs bestätigen `OpeningHours`-Klasse mit `periods` und `weekdayText`)
- Direkter HTTP-Ansatz mit `http`-Package und Places API (New) REST-Endpunkt + `X-Goog-FieldMask`-Header

### Bewertung Option B

| Kriterium | Bewertung |
|---|---|
| **Datenqualität** | Sehr hoch – strukturiert, zuverlässig, vollständig |
| **Machbarkeit** | Hoch – gute Flutter-Packages vorhanden |
| **Kosten** | Im MVP-Rahmen (<1.000 Calls/Monat) kostenlos; skaliert problematisch |
| **ToS-Risiko** | **KRITISCH** – lokale Speicherung von Öffnungszeiten verboten |
| **Offline-Kompatibilität** | Nein – Daten dürfen nicht gecacht werden |
| **Aufwand** | Niedrig bis mittel (API-Key, HTTP-Aufruf, Parsing) |

**Fazit:** Technisch ideal, aber fundamental inkompatibel mit dem App-Konzept der lokalen Datenspeicherung. Nur nutzbar, wenn die App explizit einen "Jetzt aktualisieren"-Button ohne persistente Speicherung implementiert – was dem Kernkonzept widerspricht.

---

## Option C – OpenStreetMap / Overpass API / Nominatim

### Datenverfügbarkeit und Format

OpenStreetMap speichert Öffnungszeiten als `opening_hours`-Tag mit einer standardisierten Syntax:

**Beispiele:**
```
Mo-Fr 09:00-18:00
Mo-Fr 08:00-12:00,13:00-17:30; Sa 10:00-14:00
24/7
Mo-Fr 08:00-17:00; PH off
```

Die Syntax ist gut spezifiziert. Referenz-Implementierung: `opening_hours.js` (JavaScript). Stand Dezember 2025: 4,35 Millionen `opening_hours`-Werte in OSM, Parser-Kompatibilität 99,3%.

**Zwei API-Wege für OSM:**

**Nominatim (OSM-Geocoder):**
- Suche nach Ortsname → liefert OSM-Objekt-ID
- Mit `extratags=1` werden Zusatztags wie `opening_hours` in der Antwort mitgeliefert
- Aber: Nominatim ist primär ein Geocoder, nicht für POI-Lookups ausgelegt

**Overpass API (OSM-Abfragesprache):**
- Direkte Abfrage von POIs nach Name, Koordinaten, Kategorie
- Gibt alle OSM-Tags zurück, inklusive `opening_hours` wenn vorhanden
- Overpass QL: `node["name"="Beispiel"]["opening_hours"]`

### Datenvollständigkeit

Das ist die kritische Schwachstelle:
- Weltweit haben nur **etwa ein Drittel der Supermärkte** Öffnungszeiten in OSM eingetragen
- Kleinere Unternehmen, Ärzte, Restaurants: noch deutlich weniger
- Starke regionale Unterschiede: Deutschland und Westeuropa besser abgedeckt als andere Regionen
- Daten sind community-gepflegt: können veraltet oder falsch sein
- Temporäre Öffnungszeiten (Feiertage, Sonderöffnungen) selten vorhanden

### Nutzungsbedingungen

**Nominatim (public instance):**
- Max. 1 Request/Sekunde
- Caching ist **Pflicht** (nicht optional)
- Auto-Complete verboten
- Kommerzielle Apps mit primärem Geocoding-Fokus müssen eigene Instanz betreiben
- Für den WhenOpen-Use-Case (nutzerinitiierter Einzellookup) ist die public API vertretbar, aber **rechtlich grau** für kommerzielle Apps
- Attribution erforderlich (ODbL-Lizenz)

**Overpass API (public instances):**
- Richtwert: max. ~10.000 Requests/Tag
- Public Instance nicht für End-User-Apps empfohlen – eigene Instanz empfohlen
- Selbst-Hosting bedeutet erheblichen Infrastruktur-Aufwand
- Daten unter ODbL-Lizenz → Attribution erforderlich

### Flutter-Packages

- `flutter_overpass` (4 Likes, 571 Downloads, "unverified", 15 Monate alt) – kaum gewartet
- `osm_overpass` (23 Downloads, 16 Monate alt) – quasi inaktiv
- Kein Dart-Package für OSM `opening_hours`-String-Parsing vorhanden

Für das Parsen des `opening_hours`-Strings gibt es **kein Flutter/Dart-Package**. Optionen:
1. Eigener Dart-Parser für die OSM-Syntax (erheblicher Aufwand)
2. Einfache Regex-Lösung für den Standardfall (fragil)
3. JavaScript-Interop zu `opening_hours.js` (umständlich in Flutter)

### Bewertung Option C

| Kriterium | Bewertung |
|---|---|
| **Datenqualität** | Niedrig bis mittel – ~30-50% der relevanten Orte haben Öffnungszeiten |
| **Kosten** | Kostenlos (Daten); Infrastruktur bei self-hosting |
| **Machbarkeit** | Hoch technisch (API), mittel praktisch (Parser fehlt, Packages veraltet) |
| **ToS-Risiko** | Mittel – Nominatim public API für kommerzielle Apps grenzwertig; ODbL-Attribution erforderlich |
| **Offline-Kompatibilität** | Ja – Daten dürfen gecacht/gespeichert werden (ODbL erlaubt das) |
| **Aufwand** | Hoch – kein fertiges Flutter-Package, Parser muss selbst gebaut werden |
| **Datenvollständigkeit** | Schlecht – viele Orte ohne Öffnungszeiten in OSM |

**Fazit:** Kostenlos und ToS-kompatibel mit lokaler Speicherung, aber Datenlücke ist für eine kommerzielle App inakzeptabel. Viele Nutzer-Lookups würden keine Daten liefern.

---

## Option D – Weitere Alternativen

### HERE Maps Geocoding & Search API

**Datenverfügbarkeit:** Die Discover-API liefert `openingHours` als Feld in Place-Ergebnissen – strukturierte Daten, proprietär formatiert (nicht OSM-Format).

**Kosten:** HERE bietet nach eigenen Angaben 250.000 Transaktionen/Monat kostenlos (Freemium-Modell ohne Kreditkarte). Ob Opening Hours im kostenlosen Kontingent enthalten sind, ist aus der öffentlichen Dokumentation nicht eindeutig zu klären – die Preisseite gibt keine SKU-genauen Zahlen aus.

**ToS:** Weniger restriktiv als Google – caching wird nicht explizit verboten. Attribution erforderlich.

**Flutter:** Kein offizielles Flutter-Package. REST-API via `http`-Package direkt nutzbar.

**Datenvollständigkeit:** Besser als OSM, schlechter als Google in vielen Regionen.

### Yelp Places API (Fusion API)

**Öffnungszeiten-Feld:** Vorhanden in allen Plan-Stufen (Base, Enhanced, Premium), strukturiert mit Wochentag, Start- und Endzeit im Format `HH:MM`.

**Kosten (Stand 2025–2026):**
- Trial: 5.000 Calls für 30 Tage – **ausdrücklich nur für nicht-öffentliche Evaluation**, kein Produktions-Release erlaubt
- Produktion: Bezahlpflicht ab dem ersten Call, kein permanentes Freikontingent für Produktion
- Preise werden nicht öffentlich kommuniziert (Enterprise-Verhandlung bei >150.000 Calls/Monat)

**ToS:** Stark restriktiv – Trial-Phase darf nicht für öffentliche Releases genutzt werden; Caching bis zu 24 Stunden erlaubt.

**Schwächen für WhenOpen:** Primär US-fokussiert. Europäische Datenabdeckung deutlich schwächer als Google.

### Foursquare Places API

**Öffnungszeiten:** Fallen unter **Premium-Tier** – kein Freikontingent, ab dem ersten Call kostenpflichtig. Preis: $18,75 / 1.000 Calls. Ab Juni 2026 nur noch 500 Free Pro Calls.

**Fazit:** Für eine kleine App mit dem Fokus auf Öffnungszeiten ungeeignet.

### Vergleichstabelle Alternativen

| Anbieter | Öffnungszeiten | Freikontingent Produktion | Caching erlaubt | Europa-Abdeckung |
|---|---|---|---|---|
| Google Places API | Ja (Enterprise SKU) | 1.000 Calls/Monat | Nein | Exzellent |
| HERE Maps | Ja | 250.000 Trans./Monat* | Ja (vermutlich) | Gut |
| Yelp Fusion | Ja | Keines | 24h max | Schwach (EU) |
| Foursquare | Ja (Premium) | 500 Pro Calls | k.A. | Mittel |
| OpenStreetMap | Ja (wenn vorhanden) | Kostenlos | Ja (ODbL) | Lückenhaft |

*HERE: Kontingentgrösse aus Drittquellen, offiziell nicht klar dokumentiert.

---

## Gesamtbewertungsmatrix

| Kriterium | Gewicht | Share-Intent (A) | Google Places (B) | OSM/Overpass (C) | HERE Maps (D1) |
|---|---|---|---|---|---|
| Nutzer-Komfort | 25% | 5 | 4 | 3 | 3 |
| Datenqualität | 25% | – (via B) | 5 | 2 | 4 |
| Kosten | 20% | 0 (via B) | 3 | 5 | 4 |
| ToS-Kompatibilität | 20% | 3 | 1 | 4 | 4 |
| Implementierungsaufwand | 10% | 3 | 4 | 2 | 3 |
| **Gesamtpunkte** | | – | 3,3 | 3,1 | 3,7 |

*(A allein nicht bewertbar, da kein eigenständiger Datenprovider)*

---

## Empfehlungen

### Empfehlung MVP

**Primär: Manueller Import (bereits vorhanden) + Option C als optionaler OSM-Lookup**

Begründung:
1. Der manuelle Eintrag ist ToS-sicher, offline-fähig und kostenlos.
2. Ein **optionaler OSM/Overpass-Lookup** ergänzt den manuellen Eintrag: Nutzer gibt Ortsname ein, App sucht in OSM, zeigt gefundene Zeiten zur Bestätigung an. Wenn keine OSM-Daten vorhanden → manuell weiter.
3. **Kein Google Places API im MVP**, weil der No-Caching-Zwang fundamental dem App-Konzept widerspricht.
4. HERE Maps ist eine Alternative zu OSM im MVP, wenn die 250.000 Free Calls bestätigt werden – aber das erfordert weitere Verifizierung der ToS-Details.

**MVP-Implementierungsstrategie:**
- Formular für manuellen Eintrag (done)
- Optional: Ortsname-Suche via Nominatim (1 req/s, extratags=1), Ergebnis zur Bestätigung zeigen
- Öffnungszeiten werden immer lokal in der App gespeichert (eigenes Datenformat, nicht das OSM-Format 1:1)
- Attribution: "Daten von OpenStreetMap-Mitwirkenden" anzeigen

**Aufwand:** 1–2 Tage Implementierung, kein API-Key, keine Kosten.

### Empfehlung v2 (nach erstem Release)

**Option A + B als Premium-Feature mit optionalem API-Key**

Nach dem MVP-Release und erstem Nutzer-Feedback:
1. **Share-Intent aus Google Maps** implementieren (Option A) – Nutzer kann aus Maps-App direkt teilen
2. **Google Places API-Lookup** (Option B) als Backend – liefert hochwertige, strukturierte Daten
3. **Juristisches Problem lösen:** Nutzer bestätigt, dass Daten nur zu persönlichem Gebrauch gespeichert werden. Google-ToS schränkt kommerzielles Caching ein, nicht persönliches Speichern durch den Nutzer. Eine Rechtsberatung zu diesem Punkt ist ratsam.
4. **Alternativ** (ToS-sicher): App speichert nur Place ID lokal, lädt Öffnungszeiten bei jedem Widget-Refresh nach. Nur bei bestehender Verbindung möglich.

**Kosten v2:** Bei <1.000 API-Calls/Monat kostenlos (1.000 Free Events/Monat im Enterprise-SKU). Bei Wachstum: $20 / 1.000 Calls.

---

## Risiken und offene Fragen

| Risiko | Wahrscheinlichkeit | Massnahme |
|---|---|---|
| Google schränkt Place ID in geteilten URLs ein | Mittel | Fallback auf Ortsname-Suche |
| OSM-Daten für Nutzer-Orte nicht vorhanden | Hoch | Immer manuellen Eintrag als Fallback anbieten |
| HERE Free Tier kleiner als kommuniziert | Mittel | ToS und Preisseite vor v2-Entscheidung prüfen |
| Google ToS-Verletzung durch lokale Speicherung | Hoch (wenn genutzt) | Rechtsberatung oder ToS-konformen Refresh-Ansatz wählen |
| Nominatim-Sperrung bei zu vielen Requests | Niedrig (bei <10 Nutzern aktiv) | Rate-Limiter einbauen, Ergebnisse cachen |

---

## Quellen

- [Google Maps Platform Billing & Pricing](https://developers.google.com/maps/billing-and-pricing/pricing)
- [Google Places API Usage and Billing](https://developers.google.com/maps/documentation/places/web-service/usage-and-billing)
- [Google Places API Policies](https://developers.google.com/maps/documentation/places/web-service/policies)
- [Google Places API Place Details (New)](https://developers.google.com/maps/documentation/places/web-service/place-details)
- [Google Maps URLs – Place ID in shared links](https://developers.google.com/maps/architecture/maps-url)
- [OpenStreetMap Key:opening_hours](https://wiki.openstreetmap.org/wiki/Key:opening_hours)
- [Overpass API – Commons (Usage Policy)](https://dev.overpass-api.de/overpass-doc/en/preface/commons.html)
- [Nominatim Usage Policy (OSMF)](https://operations.osmfoundation.org/policies/nominatim/)
- [Foursquare Places API Pricing (2025)](https://app.getcamino.ai/learn/foursquare-places-api-pricing)
- [Yelp Places API Plans](https://docs.developer.yelp.com/docs/plans)
- [Google Maps API Pricing 2026 (Woosmap)](https://www.woosmap.com/blog/google-maps-api-pricing-breakdown)
- [HERE Maps API Pricing Guide](https://local-eyes.nl/here-maps-api-costs-in-2024/)
- [receive_sharing_intent Flutter Package](https://pub.dev/packages/receive_sharing_intent)
- [flutter_google_places_sdk Package](https://pub.dev/packages/flutter_google_places_sdk)
- [opening_hours.js GitHub](https://github.com/opening-hours/opening_hours.js/)
- [HN: OSM Opening Hours Discussion](https://news.ycombinator.com/item?id=37031835)
- [Google Places API Now Costs $275/Month (DEV Community)](https://dev.to/marketoracle/google-places-api-now-costs-275month-heres-a-free-alternative-29ic)
- [Google Maps API Pricing 2026 (MapAtlas)](https://mapatlas.eu/blog/google-maps-api-pricing-2026)
