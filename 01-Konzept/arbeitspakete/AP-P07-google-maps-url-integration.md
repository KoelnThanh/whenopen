# Arbeitspaket

## AP-P07 — Google Maps URL-Integration

| Feld | Wert |
|---|---|
| **Plan-ID** | P07 |
| **Spec-Referenz** | Workflow 4 (Detailansicht), Edge Cases (Google Maps App nicht installiert) |
| **Komponente** | Data-Layer (URL-Service) |
| **Agent** | Georg |
| **Geschätzte Größe** | ~200 LOC · ~30K Tokens |
| **Abhängig von** | P05 |
| **Übergabe an** | P09 |

---

## Ziel

Einen `UrlService` implementieren, der Google Maps, Telefonwähler und Adress-Karten-App aus der Detailansicht heraus öffnet — mit korrektem Fallback wenn die jeweilige App nicht installiert ist.

---

## Eingaben

- `lib/screens/detail_screen.dart` aus P05 (Integrationspunkt)
- `1.1-spezifikation.md` → Edge Cases (Google Maps App nicht installiert → Browser-Fallback)
- `1.1-spezifikation.md` → Entscheidung: kein SDK, kein API-Key, nur URL-Scheme

---

## Aufgaben

1. **`url_launcher`-Dependency prüfen**
   - Falls noch nicht in pubspec.yaml: ergänzen (`url_launcher`)
   - Android-Konfiguration: `AndroidManifest.xml` um `<queries>`-Block ergänzen (Android 11+ benötigt explizite Intent-Deklaration für `https`, `tel`, `geo`)

2. **`UrlService` implementieren** (`lib/services/url_service.dart`)

   **`openGoogleMaps(String googleMapsLink) → Future<void>`**
   - Versucht direkt den gespeicherten Link zu öffnen (öffnet Google Maps App wenn installiert)
   - Fallback: `https://`-URL im Browser öffnen
   - Wenn Link leer oder ungültig: `SnackBar` "Kein Google Maps Link gespeichert"

   **`openAddressInMaps(String adresse) → Future<void>`**
   - Öffnet `geo:0,0?q=[encodedAdresse]` — öffnet Standard-Karten-App (Google Maps oder andere)
   - Fallback: `https://maps.google.com/?q=[encodedAdresse]` im Browser
   - URL-Encoding der Adresse (`Uri.encodeComponent`)

   **`openPhone(String telefonnummer) → Future<void>`**
   - Öffnet `tel:[nummer]` — öffnet Telefonwähler
   - Wenn `canLaunchUrl` false: `SnackBar` "Kein Telefonwähler verfügbar"

3. **Integration in `DetailScreen`** (P05-Datei anpassen)
   - "In Google Maps öffnen"-Button ruft `UrlService.openGoogleMaps(location.googleMapsLink)` auf
   - Adresse (wenn vorhanden) als tippbarer Text: ruft `UrlService.openAddressInMaps(location.adresse)` auf
   - Telefonnummer (wenn vorhanden) als tippbarer Text: ruft `UrlService.openPhone(location.telefon)` auf

4. **URL-Validierung beim Speichern** (in `ValidationService` aus P04 ergänzen)
   - Google Maps Link: wenn gesetzt, muss mit `https://` beginnen
   - Fehlermeldung: "Bitte gib eine gültige URL ein (beginnt mit https://)"

---

## Lieferobjekt

- `lib/services/url_service.dart`
- `android/app/src/main/AndroidManifest.xml` — `<queries>`-Block ergänzt
- `lib/screens/detail_screen.dart` — URL-Aktionen integriert
- `lib/services/validation_service.dart` — URL-Validierung ergänzt
- `lib/l10n/app_de.arb` — Fehlermeldungen ergänzt

---

## Akzeptanzkriterien

- [ ] Google Maps Link öffnet Google Maps App wenn installiert
- [ ] Google Maps Link öffnet Browser wenn Google Maps nicht installiert
- [ ] Adresse als tippbarer Link öffnet Karten-App
- [ ] Telefonnummer als tippbarer Link öffnet Telefonwähler
- [ ] Fehlende/ungültige Felder zeigen SnackBar statt Crash
- [ ] URL-Validierung verhindert Speichern ungültiger Links

---

## Hinweise

- `url_launcher` ist das Standardpackage für diesen Anwendungsfall in Flutter — keine Alternative nötig
- Android 11+ (API 30+) erfordert `<queries>`-Block im Manifest für `canLaunchUrl` — ohne diesen Block gibt `canLaunchUrl` immer `false` zurück, auch wenn die App installiert ist
- Google Maps URL-Format: `https://maps.google.com/?cid=[cid]` öffnet direkt den Ort (wenn aus Google Maps geteilt), `https://maps.google.com/?q=[name]` öffnet Suche. Beides funktioniert als Deep Link in die Google Maps App
- Dieses Paket ist klein — wenn Zeit übrig: Smoke-Test auf echtem Gerät direkt einbauen
