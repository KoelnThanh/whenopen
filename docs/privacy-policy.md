# Datenschutzerklärung für WhenOpen

**Stand:** 14. Juni 2026
**App:** WhenOpen (Android)
**Verantwortlich:** Thanh Nguyen · koeln.thanh@gmail.com

WhenOpen ist eine Offline-App. Sie hilft dir, persönliche Öffnungszeiten zu speichern
und auf einen Blick zu sehen, was gerade geöffnet ist. Datenschutz ist eingebaut, nicht
nachträglich angeschraubt.

## Kurzfassung

- **Kein Konto, kein Login, kein Tracking.**
- **Keine Werbung, keine Analyse-SDKs, keine Cookies.**
- Alle von dir eingegebenen Daten bleiben **lokal auf deinem Gerät**.
- WhenOpen sendet Daten **nur** an Dritte, wenn du aktiv die OSM-Suche oder die
  Umkreissuche nutzt (siehe unten). Bei der Textsuche ist das dein Suchbegriff, bei
  der Umkreissuche zusätzlich deine **ungefähre Position**.

## Welche Daten verarbeitet die App?

Du legst Orte mit Namen, Öffnungszeiten und optional Adresse, Telefonnummer, Kategorie und
einem Google-Maps-Link an. Diese Einträge werden ausschließlich in einer Datei im privaten
App-Speicher deines Geräts abgelegt (`whenopen_data.json`). Sie werden **nicht** an uns oder
Dritte übertragen und verlassen dein Gerät nicht, außer du exportierst sie selbst.

Die App verlangt **keine** personenbezogenen Daten über dich (Name, E-Mail, Standort des
Geräts o. Ä.).

## Optionale OSM-Suche (Nominatim und Overpass)

Beide folgenden Funktionen sind freiwillig — nutzt du sie nicht, verlässt **kein** Datenpaket
dein Gerät.

**Textsuche (Nominatim):** Wählst du beim Anlegen eines Ortes „Ort aus dem Web übernehmen",
sendet die App deinen eingegebenen **Suchbegriff** an den Geocoding-Dienst **Nominatim** von
OpenStreetMap (`nominatim.openstreetmap.org`), um passende Orte und ggf. öffentlich
hinterlegte Öffnungszeiten vorzuschlagen.

**Umkreissuche (Overpass):** Nutzt du „Orte in der Nähe", sendet die App deine **ungefähre
Position** (aus deiner hinterlegten Heimatadresse abgeleitet, auf etwa 11 m gerundet) samt
gewähltem Radius an die **Overpass-API** von OpenStreetMap (`overpass-api.de`), um Orte mit
Öffnungszeiten im Umkreis zu finden. Eine genaue Geräte-Ortung (GPS) findet **nicht** statt.

Bei beiden Diensten sendet die App im technischen Anfrage-Kopf (User-Agent) eine
**Projekt-Kontaktangabe** (ein Link zur Projektseite) mit — wie es die
[Nominatim Usage Policy](https://operations.osmfoundation.org/policies/nominatim/) verlangt.
Es gilt die [OSMF-Datenschutzrichtlinie](https://wiki.osmfoundation.org/wiki/Privacy_Policy).

## Externe Apps (Karten / Telefon)

Tippst du auf eine Adresse, einen Maps-Link oder eine Telefonnummer, öffnet WhenOpen die
jeweilige App deines Geräts (Karten, Browser, Telefon). Was dort geschieht, unterliegt der
Datenschutzerklärung der jeweiligen App — WhenOpen übergibt nur das von dir hinterlegte Ziel.

## Berechtigungen

- **Internet** — nur für die optionale OSM-Suche.
- **Exakte Alarme / Aufwecken** — damit das Home-Widget den Offen/Zu-Status pünktlich zur
  nächsten Öffnungs- bzw. Schließzeit aktualisiert. Es werden dabei keine Daten übertragen.

## Sichern, Teilen und Wiederherstellen

Beim „Sichern" legt die App eine **unverschlüsselte** Kopie deiner Daten als Datei im
allgemein zugänglichen Ordner `Download/WhenOpen` ab, damit du sie leicht wiederfindest und
weitergeben kannst. Diese Datei ist dadurch auch für andere Apps mit Dateizugriff lesbar —
bewahre sie entsprechend auf und teile sie nur mit Personen/Apps, denen du vertraust. Beim
„Teilen" wird zusätzlich eine temporäre Kopie erstellt und an die von dir gewählte App
übergeben. Es findet **kein** automatischer Upload und **keine** Cloud-Synchronisierung statt.

## Speicherdauer und Löschung

Deine Daten bleiben so lange gespeichert, wie du die App nutzt. Du löschst sie jederzeit,
indem du einzelne Einträge entfernst oder die App deinstallierst — danach sind die lokalen
Daten unwiderruflich entfernt. Selbst angelegte Sicherungen im Ordner `Download/WhenOpen`
musst du bei Bedarf separat löschen.

## Kinder

Die App richtet sich nicht gezielt an Kinder und erhebt keine Daten von ihnen.

## Änderungen

Wird die App um Funktionen erweitert, die das ändern, aktualisieren wir diese Erklärung und
passen das Datum oben an.

## Kontakt

Fragen zum Datenschutz: **koeln.thanh@gmail.com**
