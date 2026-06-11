// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'WhenOpen';

  @override
  String get tagMontag => 'Montag';

  @override
  String get tagDienstag => 'Dienstag';

  @override
  String get tagMittwoch => 'Mittwoch';

  @override
  String get tagDonnerstag => 'Donnerstag';

  @override
  String get tagFreitag => 'Freitag';

  @override
  String get tagSamstag => 'Samstag';

  @override
  String get tagSonntag => 'Sonntag';

  @override
  String get tagMoKurz => 'Mo';

  @override
  String get tagDiKurz => 'Di';

  @override
  String get tagMiKurz => 'Mi';

  @override
  String get tagDoKurz => 'Do';

  @override
  String get tagFrKurz => 'Fr';

  @override
  String get tagSaKurz => 'Sa';

  @override
  String get tagSoKurz => 'So';

  @override
  String statusBis(String zeit) {
    return 'bis $zeit';
  }

  @override
  String statusAb(String zeit) {
    return 'ab $zeit';
  }

  @override
  String statusMorgenAb(String zeit) {
    return 'morgen ab $zeit';
  }

  @override
  String statusTagAb(String tag, String zeit) {
    return 'ab $tag $zeit';
  }

  @override
  String get statusHeuteGeschlossen => 'heute geschlossen';

  @override
  String get statusKeineZeiten => 'Keine Öffnungszeiten';

  @override
  String get statusGeschlossen => 'Geschlossen';

  @override
  String get statusOffen => 'Geöffnet';

  @override
  String get homeLeerTitel => 'Noch keine Orte gespeichert.';

  @override
  String get homeLeerHinweis =>
      'Tippe auf +, um deinen ersten Ort hinzuzufügen.';

  @override
  String get homeOffenZahl => 'jetzt offen';

  @override
  String get homeZuZahl => 'geschlossen';

  @override
  String get alleOrte => 'Alle Orte';

  @override
  String get sonstige => 'Sonstige';

  @override
  String get anzeigen => 'Anzeigen';

  @override
  String get neueKategorie => 'Neue Kategorie';

  @override
  String get kategorienVerwalten => 'Kategorien verwalten';

  @override
  String get suche => 'Suchen';

  @override
  String get sucheHint => 'Ort suchen…';

  @override
  String get keineTreffer => 'Keine Treffer';

  @override
  String get qeNeuerOrt => 'Neuer Ort';

  @override
  String get qeBearbeiten => 'Ort bearbeiten';

  @override
  String qeSchritt(int n, int gesamt) {
    return 'Schritt $n von $gesamt';
  }

  @override
  String get qeSchrittName => 'Name';

  @override
  String get qeSchrittKategorie => 'Kategorie';

  @override
  String get qeSchrittZusatz => 'Zusatzinfos';

  @override
  String get qeNameTitel => 'Wie heißt der Ort?';

  @override
  String get qeNameHint => 'Name des Orts, z. B. Kinderarzt Müller';

  @override
  String get qeNamePflicht => 'Bitte gib einen Namen ein.';

  @override
  String get qeTagHint =>
      'Öffnungszeiten — bei Pausen einfach mehrere Blöcke anlegen.';

  @override
  String get qeGeoeffnet => 'Geöffnet';

  @override
  String get qeGleicheZeiten => 'Gleiche Zeiten';

  @override
  String get qeGeschlossen => 'Geschlossen';

  @override
  String get qeOeffnet => 'öffnet';

  @override
  String get qeSchliesst => 'schließt';

  @override
  String get qeWeitererBlock => '＋ weiterer Zeitblock';

  @override
  String get qeBlockHint =>
      'Die Lücke zwischen zwei Blöcken ist automatisch die Pause.';

  @override
  String get qeBlockEntfernen => 'Zeitblock entfernen';

  @override
  String get qeKategorieTitel => 'Welche Kategorie?';

  @override
  String get qeKategorieHint =>
      'Für Gruppierung & Filter im Widget. Frei wählbar.';

  @override
  String get qeKategorieOhne => 'Ohne Auswahl landet der Ort unter „Sonstige“.';

  @override
  String get qeZusatzTitel => 'Zusatzinfos';

  @override
  String get qeZusatzHint =>
      'Diese Felder sind optional. Du kannst sie später ergänzen.';

  @override
  String get qeAdresse => 'Adresse';

  @override
  String get qeTelefon => 'Telefonnummer';

  @override
  String get qeMapsLink => 'Google Maps Link';

  @override
  String get qeZurueck => 'Zurück';

  @override
  String get qeWeiter => 'Weiter';

  @override
  String get qeSpeichern => 'Speichern';

  @override
  String get qeAbbrechen => 'Abbrechen';

  @override
  String get valNameFehlt => 'Bitte gib einen Namen ein.';

  @override
  String get valKeinTagOffen =>
      'Trage für mindestens einen Tag eine Öffnungszeit ein.';

  @override
  String get valVonVorBis =>
      'Die Öffnungszeit muss vor der Schließzeit liegen.';

  @override
  String get valBloeckeUeberlappen =>
      'Zeitblöcke dürfen sich nicht überschneiden.';

  @override
  String get valUngueltigeUrl =>
      'Bitte gib eine gültige URL ein (beginnt mit https://).';

  @override
  String get limitHinweis => 'Maximale Anzahl von 50 Einträgen erreicht.';

  @override
  String get detailHeute => 'heute';

  @override
  String get detailBearbeiten => 'Bearbeiten';

  @override
  String get detailLoeschen => 'Löschen';

  @override
  String get detailInMapsOeffnen => 'In Google Maps öffnen';

  @override
  String get detailAdresse => 'Adresse';

  @override
  String get detailTelefon => 'Telefon';

  @override
  String get detailNichtGefunden => 'Eintrag nicht gefunden';

  @override
  String geloescht(String name) {
    return '„$name“ gelöscht';
  }

  @override
  String get rueckgaengig => 'Rückgängig';

  @override
  String get katNeuTitel => 'Neue Kategorie';

  @override
  String get katNeuHint => 'Name und Farbe — frei wählbar.';

  @override
  String get katName => 'Name';

  @override
  String get katFarbe => 'Farbe';

  @override
  String get katAnlegen => 'Anlegen';

  @override
  String get katUmbenennen => 'Umbenennen';

  @override
  String get katFarbeAendern => 'Farbe ändern';

  @override
  String get katZusammenfuehren => 'Mit anderer zusammenführen…';

  @override
  String get katLoeschen => 'Löschen';

  @override
  String katOrte(int anzahl) {
    return '$anzahl Orte';
  }

  @override
  String get katEinOrt => '1 Ort';

  @override
  String get katSonstigeHint => 'automatische Auffang-Kategorie';

  @override
  String katLoeschenWarnung(int anzahl) {
    return '$anzahl Orte fallen auf „Sonstige“ zurück.';
  }

  @override
  String katZusammenWarnung(String von, String nach) {
    return 'Alle Orte aus „$von“ wandern nach „$nach“.';
  }

  @override
  String get katAendern => 'Kategorie ändern';

  @override
  String get katZiel => 'Ziel-Kategorie';

  @override
  String get katSpeichern => 'Speichern';

  @override
  String get katTitel => 'Kategorien';

  @override
  String get urlKeinMapsLink => 'Kein Google Maps Link gespeichert';

  @override
  String get urlKeinTelefon => 'Kein Telefonwähler verfügbar';

  @override
  String get urlFehler => 'Konnte nicht geöffnet werden';

  @override
  String get osmSuchen => 'Ort aus dem Web übernehmen';

  @override
  String get osmManuell => 'Manuell eintragen';

  @override
  String get osmSuchTitel => 'Ort suchen';

  @override
  String get osmSuchHint => 'Name und Ort, z. B. „Apotheke Viersen“';

  @override
  String get osmKeineTreffer => 'Keine Treffer — bitte manuell eintragen.';

  @override
  String get osmFehler => 'Suche nicht möglich — bitte manuell eintragen.';

  @override
  String get osmBestaetigeTitel => 'Daten prüfen';

  @override
  String get osmBestaetigeHint =>
      'Daten aus dem Web — bitte prüfe, ob alles stimmt.';

  @override
  String get osmZeitenErkannt => 'Öffnungszeiten erkannt — bitte prüfen';

  @override
  String get osmZeitenNichtErkannt =>
      'Öffnungszeiten nicht erkannt — bitte manuell eintragen.';

  @override
  String get osmUebernehmen => 'Übernehmen';

  @override
  String get widgetLeer =>
      'Keine Einträge gespeichert — tippe hier, um zu starten';

  @override
  String get widgetKonfigTitel => 'Widget einrichten';

  @override
  String get widgetKonfigFrage => 'Welche Orte soll dieses Widget zeigen?';

  @override
  String get widgetHinzufuegen => 'Hinzufügen';

  @override
  String get datenFehlerTitel => 'Daten konnten nicht geladen werden';

  @override
  String get datenFehlerText =>
      'Die gespeicherten Daten waren beschädigt. Eine Sicherungskopie wurde angelegt, die App startet leer.';

  @override
  String get ok => 'OK';

  @override
  String get speichernFehlgeschlagen => 'Speichern fehlgeschlagen';

  @override
  String get exportTeilen => 'Daten exportieren';
}
