# Play Store Listing — WhenOpen (DE)

<!-- P09: Vorlage zum Einpflegen in die Google Play Console.
     Zeichenlimits: Kurzbeschreibung 80, Langbeschreibung 4.000. -->

## Stammdaten

| Feld | Wert |
|---|---|
| App-Name | **WhenOpen** |
| Paketname | `com.whenopen.when_open` |
| Kategorie | Produktivität |
| Inhaltseinstufung | Ohne Altersbeschränkung (USK 0) |
| Preis | Kostenlos, keine Werbung, keine In-App-Käufe |
| Sprachen | Deutsch (de) |
| Privacy-Policy-URL | _(nach GitHub-Pages-Aktivierung eintragen)_ z. B. `https://koelnthanh.github.io/whenopen/privacy-policy` |
| Kontakt-E-Mail | koeln.thanh@gmail.com |

## Kurzbeschreibung (max. 80 Zeichen)

> Öffnungszeiten deiner Orte auf einen Blick – im Widget, ganz ohne Suchen.

*(72 Zeichen. Alternative: „Was ist gerade offen? Deine Lieblingsorte als Widget, lokal & ohne Konto." = 78)*

## Langbeschreibung (max. 4.000 Zeichen)

> **Nie wieder Öffnungszeiten googeln.**
>
> Du kennst das: Schnell noch zum Bürgeramt, zur Apotheke oder zum Hofladen – aber haben die
> jetzt überhaupt auf? WhenOpen beantwortet das in einer Sekunde, direkt auf deinem
> Startbildschirm.
>
> WhenOpen speichert die Öffnungszeiten der Orte, die DU regelmäßig brauchst, und zeigt dir
> auf einen Blick, was gerade geöffnet ist und was nicht. Kein Suchen, kein Konto, keine
> Cloud – alles bleibt lokal auf deinem Gerät.
>
> **Das kann WhenOpen:**
>
> ✅ **Home-Widget** – Offen/Geschlossen-Übersicht direkt auf dem Startbildschirm. Tippe einen
> Ort an und springe sofort zu seinen Details.
>
> ✅ **Schnell befüllt** – Ein geführter Mo–So-Dialog mit klugen Vorschlagswerten. Geteilte
> Vormittags-/Nachmittagszeiten und Mittagspausen? Kein Problem – beliebig viele Zeitblöcke
> pro Tag.
>
> ✅ **Import aus dem Web** – Optionaler Ort-Suchassistent (OpenStreetMap): Name eintippen,
> Adresse, Telefon und – falls hinterlegt – Öffnungszeiten übernehmen, prüfen, fertig.
>
> ✅ **Kategorien & Filter** – Behörden, Gesundheit, Einkauf … Gruppiere deine Orte und richte
> mehrere Widgets ein, jedes mit eigenem Filter.
>
> ✅ **Immer pünktlich** – Der Status kippt exakt zur Öffnungs- bzw. Schließzeit, ohne deinen
> Akku leerzusaugen.
>
> ✅ **Schnellzugriff** – Adresse in Karten öffnen oder direkt anrufen, mit einem Tipp.
>
> **Für wen ist das gemacht?**
>
> • **Eltern**, die wissen müssen, ob der Kinderarzt gerade Sprechstunde hat.
> • **Pendler und Berufstätige**, die Behörden- und Ladenzeiten im Kopf behalten müssen.
> • **Menschen mit vielen Anlaufstellen** – Sozialarbeit, Pflege, Facility-Management – die
>   Dutzende Orte mit unterschiedlichen Zeiten jonglieren.
> • **Alle**, die genug davon haben, dieselben Öffnungszeiten immer wieder zu suchen.
>
> **Privatsphäre zuerst.**
>
> WhenOpen sammelt keine personenbezogenen Daten, zeigt keine Werbung und braucht kein Login.
> Deine Einträge bleiben auf deinem Gerät. Internet wird nur verwendet, wenn du selbst die
> optionale Ortssuche nutzt.
>
> Mach deinen Alltag ein bisschen leichter – frag nicht „Wann haben die auf?", schau einfach
> auf WhenOpen.

## Screenshots (mind. 2 Hochformat, 1080×1920 oder höher)

1. **Hauptliste** – Orte nach Kategorie gruppiert mit Offen/Geschlossen-Status
   *(im Repo bereits als Verifikations-Shot vorhanden; sauber neu aufnehmen für den Store)*
2. **Detailansicht** – Wochenplan mit Mehrblock-Zeiten, „heute" hervorgehoben
3. **Widget auf dem Startbildschirm** – Offen/Zu-Übersicht
4. *(optional)* **Schnelleintrag** oder **OSM-Import „Daten prüfen"**

Feature Graphic (1024×500) optional, aber empfohlen.

## Hinweise zur Einreichung

- Datenschutzformular der Play Console: „Es werden keine Nutzerdaten erfasst oder geteilt"
  – Ausnahme dokumentieren: optionale Standort-/Ortssuche sendet nur den Suchbegriff an
  OpenStreetMap-Nominatim (keine Nutzer-IDs).
- Berechtigungen begründen: `INTERNET` (optionale Suche), exakte Alarme/`WAKE_LOCK`
  (pünktliche Widget-Aktualisierung).
- Erst **Internal Testing** (1–2 Tester), dann Production. Review-Zeit 1–7 Tage einplanen.
