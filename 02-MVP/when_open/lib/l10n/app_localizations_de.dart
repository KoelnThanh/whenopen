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
  String get qeSchrittZeiten => 'Öffnungszeiten';

  @override
  String get qeWocheTitel => 'Wann hat es geöffnet?';

  @override
  String get qeNochFestlegen => 'Noch festlegen';

  @override
  String qeWieTag(String tag) {
    return 'Wie $tag';
  }

  @override
  String qeWeiterZu(String tag) {
    return 'Weiter zu $tag';
  }

  @override
  String get qeFertig => 'Fertig';

  @override
  String get qeStartFrage => 'Wie möchtest du den Ort anlegen?';

  @override
  String get qeStartHinweis =>
      'Am einfachsten übernimmst du einen echten Ort — Adresse und Öffnungszeiten kommen dann automatisch mit.';

  @override
  String get qeStartSuchenInfo =>
      'Nach Name suchen, Daten aus OpenStreetMap übernehmen.';

  @override
  String get qeStartUmkreisInfo =>
      'Orte rund um deine Heimatadresse durchsuchen.';

  @override
  String get qeStartOder => 'oder';

  @override
  String get qeManuell => 'Manuell eingeben';

  @override
  String get qeManuellInfo => 'Name und Öffnungszeiten selbst eintippen.';

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

  @override
  String get menueSichern => 'Sichern';

  @override
  String get menueTeilen => 'Teilen';

  @override
  String get menueWiederherstellen => 'Wiederherstellen';

  @override
  String get sichernBetreff => 'WhenOpen-Sicherung';

  @override
  String sichernErfolg(String ordner) {
    return 'Gesichert in $ordner. Die Datei ist unverschlüsselt und für andere Apps lesbar.';
  }

  @override
  String get sichernKeineBerechtigung =>
      'Bitte Speicher-Berechtigung erteilen und erneut sichern.';

  @override
  String get sichernFehler => 'Sichern fehlgeschlagen';

  @override
  String get teilenFehler => 'Teilen fehlgeschlagen';

  @override
  String get wiederherstellenTitel => 'Wiederherstellen?';

  @override
  String get wiederherstellenLetzte => 'Letzte Sicherung laden';

  @override
  String get wiederherstellenLetzteInfo => 'Aus dem Ordner Download/WhenOpen';

  @override
  String get wiederherstellenDatei => 'Datei wählen…';

  @override
  String get wiederherstellenDateiInfo =>
      'Aus Dateien, Downloads oder einer empfangenen Nachricht';

  @override
  String get wiederherstellenKeine =>
      'Keine Sicherung im Ordner Download/WhenOpen gefunden.';

  @override
  String wiederherstellenVorschau(int orte, int kategorien) {
    String _temp0 = intl.Intl.pluralLogic(
      orte,
      locale: localeName,
      other: '$orte Orte',
      one: '1 Ort',
      zero: 'keine Orte',
    );
    String _temp1 = intl.Intl.pluralLogic(
      kategorien,
      locale: localeName,
      other: '$kategorien Kategorien',
      one: '1 Kategorie',
      zero: 'keine Kategorien',
    );
    return 'Diese Sicherung enthält $_temp0 und $_temp1.';
  }

  @override
  String wiederherstellenWarnung(int anzahl) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: '$anzahl Orte',
      one: '1 Ort',
      zero: 'Daten',
    );
    return 'Deine jetzigen $_temp0 werden vorher automatisch gesichert.';
  }

  @override
  String get wiederherstellenAktion => 'Wiederherstellen';

  @override
  String get wiederherstellenErfolg => 'Daten wiederhergestellt.';

  @override
  String get wiederherstellenFehler =>
      'Keine gültige WhenOpen-Sicherung — nichts geändert.';

  @override
  String get abbrechen => 'Abbrechen';

  @override
  String get menueEinstellungen => 'Einstellungen';

  @override
  String get einstTitel => 'Einstellungen';

  @override
  String get einstHeimatTitel => 'Heimatadresse';

  @override
  String get einstHeimatInfo =>
      'Für die Umkreissuche „Orte in der Nähe“. Wird einmalig zu Koordinaten aufgelöst und bleibt lokal — keine Standortfreigabe nötig.';

  @override
  String get einstHeimatKeine => 'Noch keine Heimatadresse hinterlegt.';

  @override
  String get einstHeimatSuchen => 'Adresse suchen';

  @override
  String get einstHeimatSuchHint =>
      'Straße und Ort, z. B. „Hauptstraße 1, Köln“';

  @override
  String get einstHeimatEntfernen => 'Entfernen';

  @override
  String get einstHeimatKeineTreffer =>
      'Keine Adresse gefunden — bitte Schreibweise prüfen.';

  @override
  String get einstHeimatSuchfehler => 'Suche nicht möglich — bist du online?';

  @override
  String get einstUmkreisTitel => 'Suchradius';

  @override
  String einstUmkreisMeter(int meter) {
    return '$meter m';
  }

  @override
  String einstUmkreisKm(String km) {
    return '$km km';
  }

  @override
  String get einstSpeichern => 'Speichern';

  @override
  String get einstGespeichert => 'Einstellungen gespeichert.';

  @override
  String get einstAttribution =>
      'Ortsdaten: © OpenStreetMap-Mitwirkende (ODbL)';

  @override
  String get umkreisSuchen => 'Orte in der Nähe';

  @override
  String get umkreisTitel => 'Orte in der Nähe';

  @override
  String umkreisRadiusInfo(String radius, String adresse) {
    return '$radius um $adresse';
  }

  @override
  String get umkreisLaedt => 'Suche Orte in deiner Nähe…';

  @override
  String get umkreisKeineTreffer =>
      'Keine Orte mit Öffnungszeiten im Umkreis gefunden. Erhöhe ggf. den Radius in den Einstellungen.';

  @override
  String get umkreisFehler =>
      'Suche nicht möglich — bitte später erneut versuchen.';

  @override
  String get umkreisKeineHeimat =>
      'Hinterlege zuerst deine Heimatadresse in den Einstellungen.';

  @override
  String get umkreisZuEinstellungen => 'Zu den Einstellungen';

  @override
  String get menueUeber => 'Über WhenOpen';

  @override
  String get ueberTitel => 'Über WhenOpen';

  @override
  String get ueberTagline => 'Persönliche Öffnungszeiten auf einen Blick.';

  @override
  String get ueberUnterstuetzenTitel => 'Unterstützen';

  @override
  String get ueberUnterstuetzenHinweis =>
      'WhenOpen ist und bleibt kostenlos — es schaltet nichts frei.';

  @override
  String get ueberKaffeeButton => 'Spendier mir einen Kaffee ☕';

  @override
  String get ueberLinkFehler => 'Link konnte nicht geöffnet werden.';

  @override
  String ueberVersion(String version) {
    return 'Version $version';
  }

  @override
  String get ueberKontaktTitel => 'Kontakt & Feedback';

  @override
  String get ueberKontaktHinweis =>
      'Fragen, Wünsche oder ein Fehler aufgetaucht? Ich freue mich über deine Nachricht.';

  @override
  String get ueberKontaktButton => 'E-Mail schreiben';

  @override
  String get ueberKontaktBetreff => 'WhenOpen-Feedback';

  @override
  String get tutorialDialogTitel => 'Kurze Einführung?';

  @override
  String get tutorialDialogText =>
      'Es sieht aus, als wärst du neu hier. Möchtest du eine kurze Tour durch WhenOpen — Kategorien, Daten und „Orte in der Nähe“?';

  @override
  String get tutorialDialogJa => 'Tour starten';

  @override
  String get tutorialDialogNein => 'Nein, danke';

  @override
  String get onboardingUeberspringen => 'Überspringen';

  @override
  String get onboardingWeiter => 'Weiter';

  @override
  String get onboardingErsterOrt => 'Ersten Ort anlegen';

  @override
  String get onboardingFertig => 'Fertig';

  @override
  String get onboardingWillkommenTitel => 'Willkommen bei WhenOpen';

  @override
  String get onboardingWillkommenText =>
      'Behalte die Öffnungszeiten deiner wichtigen Orte im Blick. Alles bleibt lokal auf deinem Gerät — kein Konto, keine Cloud, kein Tracking.';

  @override
  String get onboardingKategorienTitel => 'Kategorien';

  @override
  String get onboardingKategorienText =>
      'Ordne deine Orte in frei wählbare Kategorien wie „Ärzte“ oder „Einkaufen“ — praktisch zum Gruppieren und Filtern. Ohne Auswahl landet ein Ort unter „Sonstige“.';

  @override
  String get onboardingDatenTitel => 'Woher kommen die Daten?';

  @override
  String get onboardingDatenText =>
      'Du kannst Orte aus dem Web übernehmen (OpenStreetMap), „Orte in der Nähe“ suchen oder Zeiten von Hand eintragen. Deine Sammlung lässt sich jederzeit sichern und wiederherstellen.';

  @override
  String get onboardingAdresseTitel => 'Deine Adresse (einmalig)';

  @override
  String get onboardingAdresseText =>
      'Damit du kein GPS nutzen musst, fragen wir einmal nach deiner Adresse. Ohne Adresse wird die Funktion „Orte in der Nähe“ nicht freigeschaltet.';

  @override
  String get onboardingAdresseGesetzt =>
      'Super — „Orte in der Nähe“ ist jetzt freigeschaltet.';

  @override
  String get onboardingWidgetTitel => 'Das Herzstück: das Widget';

  @override
  String get onboardingWidgetText =>
      'WhenOpen spielt seine Stärke erst auf dem Startbildschirm aus: Das Widget zeigt dir auf einen Blick, welche Orte gerade geöffnet sind — ganz ohne die App zu öffnen. Richtig nützlich wird die App also erst, wenn du das Widget anlegst.';

  @override
  String get onboardingWidgetSchritt1 =>
      'Tippe lange auf eine freie Stelle des Startbildschirms.';

  @override
  String get onboardingWidgetSchritt2 => 'Wähle „Widgets“ und suche WhenOpen.';

  @override
  String get onboardingWidgetSchritt3 =>
      'Zieh das Widget auf den Startbildschirm — fertig.';

  @override
  String get onboardingFertigTitel => 'Los geht’s!';

  @override
  String get onboardingFertigText =>
      'Du bist startklar. Am einfachsten legst du deinen ersten Ort über „Orte in der Nähe“ an — und denk ans Widget auf dem Startbildschirm.';

  @override
  String get tutorialQeHinweis =>
      'Tipp: Über „Orte in der Nähe“ findest du einen Ort automatisch — Name, Adresse und Öffnungszeiten werden direkt übernommen.';

  @override
  String get spendeDialogTitel => 'Gefällt dir WhenOpen?';

  @override
  String spendeDialogText(int anzahl) {
    return 'Du hast schon $anzahl Orte gespeichert — schön, dass dir die App hilft! Sie ist und bleibt kostenlos. Wenn du magst, spendier mir einen Kaffee oder schick mir kurz Feedback.';
  }

  @override
  String get spendeDialogFeedback => 'Feedback';

  @override
  String get spendeDialogSpaeter => 'Später';

  @override
  String get qeEmpfohlen => 'Empfohlen';

  @override
  String get qeUebernehmenTitel => 'Zeiten übernehmen';

  @override
  String get menueFaq => 'Fragen & Antworten';

  @override
  String get faqTitel => 'Fragen & Antworten';

  @override
  String get faqUntertitel =>
      'Kurz erklärt, wie WhenOpen mit deinen Daten umgeht.';

  @override
  String get einstDesignTitel => 'Darstellung';

  @override
  String get einstDesignInfo =>
      'Hell, dunkel oder automatisch dem System folgen.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeHell => 'Hell';

  @override
  String get themeDunkel => 'Dunkel';
}
