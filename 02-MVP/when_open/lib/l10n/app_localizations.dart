import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de')];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'WhenOpen'**
  String get appTitle;

  /// No description provided for @tagMontag.
  ///
  /// In de, this message translates to:
  /// **'Montag'**
  String get tagMontag;

  /// No description provided for @tagDienstag.
  ///
  /// In de, this message translates to:
  /// **'Dienstag'**
  String get tagDienstag;

  /// No description provided for @tagMittwoch.
  ///
  /// In de, this message translates to:
  /// **'Mittwoch'**
  String get tagMittwoch;

  /// No description provided for @tagDonnerstag.
  ///
  /// In de, this message translates to:
  /// **'Donnerstag'**
  String get tagDonnerstag;

  /// No description provided for @tagFreitag.
  ///
  /// In de, this message translates to:
  /// **'Freitag'**
  String get tagFreitag;

  /// No description provided for @tagSamstag.
  ///
  /// In de, this message translates to:
  /// **'Samstag'**
  String get tagSamstag;

  /// No description provided for @tagSonntag.
  ///
  /// In de, this message translates to:
  /// **'Sonntag'**
  String get tagSonntag;

  /// No description provided for @tagMoKurz.
  ///
  /// In de, this message translates to:
  /// **'Mo'**
  String get tagMoKurz;

  /// No description provided for @tagDiKurz.
  ///
  /// In de, this message translates to:
  /// **'Di'**
  String get tagDiKurz;

  /// No description provided for @tagMiKurz.
  ///
  /// In de, this message translates to:
  /// **'Mi'**
  String get tagMiKurz;

  /// No description provided for @tagDoKurz.
  ///
  /// In de, this message translates to:
  /// **'Do'**
  String get tagDoKurz;

  /// No description provided for @tagFrKurz.
  ///
  /// In de, this message translates to:
  /// **'Fr'**
  String get tagFrKurz;

  /// No description provided for @tagSaKurz.
  ///
  /// In de, this message translates to:
  /// **'Sa'**
  String get tagSaKurz;

  /// No description provided for @tagSoKurz.
  ///
  /// In de, this message translates to:
  /// **'So'**
  String get tagSoKurz;

  /// No description provided for @statusBis.
  ///
  /// In de, this message translates to:
  /// **'bis {zeit}'**
  String statusBis(String zeit);

  /// No description provided for @statusAb.
  ///
  /// In de, this message translates to:
  /// **'ab {zeit}'**
  String statusAb(String zeit);

  /// No description provided for @statusMorgenAb.
  ///
  /// In de, this message translates to:
  /// **'morgen ab {zeit}'**
  String statusMorgenAb(String zeit);

  /// No description provided for @statusTagAb.
  ///
  /// In de, this message translates to:
  /// **'ab {tag} {zeit}'**
  String statusTagAb(String tag, String zeit);

  /// No description provided for @statusHeuteGeschlossen.
  ///
  /// In de, this message translates to:
  /// **'heute geschlossen'**
  String get statusHeuteGeschlossen;

  /// No description provided for @statusKeineZeiten.
  ///
  /// In de, this message translates to:
  /// **'Keine Öffnungszeiten'**
  String get statusKeineZeiten;

  /// No description provided for @statusGeschlossen.
  ///
  /// In de, this message translates to:
  /// **'Geschlossen'**
  String get statusGeschlossen;

  /// No description provided for @statusOffen.
  ///
  /// In de, this message translates to:
  /// **'Geöffnet'**
  String get statusOffen;

  /// No description provided for @homeLeerTitel.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Orte gespeichert.'**
  String get homeLeerTitel;

  /// No description provided for @homeLeerHinweis.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf +, um deinen ersten Ort hinzuzufügen.'**
  String get homeLeerHinweis;

  /// No description provided for @homeOffenZahl.
  ///
  /// In de, this message translates to:
  /// **'jetzt offen'**
  String get homeOffenZahl;

  /// No description provided for @homeZuZahl.
  ///
  /// In de, this message translates to:
  /// **'geschlossen'**
  String get homeZuZahl;

  /// No description provided for @alleOrte.
  ///
  /// In de, this message translates to:
  /// **'Alle Orte'**
  String get alleOrte;

  /// No description provided for @sonstige.
  ///
  /// In de, this message translates to:
  /// **'Sonstige'**
  String get sonstige;

  /// No description provided for @anzeigen.
  ///
  /// In de, this message translates to:
  /// **'Anzeigen'**
  String get anzeigen;

  /// No description provided for @neueKategorie.
  ///
  /// In de, this message translates to:
  /// **'Neue Kategorie'**
  String get neueKategorie;

  /// No description provided for @kategorienVerwalten.
  ///
  /// In de, this message translates to:
  /// **'Kategorien verwalten'**
  String get kategorienVerwalten;

  /// No description provided for @suche.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get suche;

  /// No description provided for @sucheHint.
  ///
  /// In de, this message translates to:
  /// **'Ort suchen…'**
  String get sucheHint;

  /// No description provided for @keineTreffer.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer'**
  String get keineTreffer;

  /// No description provided for @qeNeuerOrt.
  ///
  /// In de, this message translates to:
  /// **'Neuer Ort'**
  String get qeNeuerOrt;

  /// No description provided for @qeBearbeiten.
  ///
  /// In de, this message translates to:
  /// **'Ort bearbeiten'**
  String get qeBearbeiten;

  /// No description provided for @qeSchritt.
  ///
  /// In de, this message translates to:
  /// **'Schritt {n} von {gesamt}'**
  String qeSchritt(int n, int gesamt);

  /// No description provided for @qeSchrittName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get qeSchrittName;

  /// No description provided for @qeSchrittKategorie.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get qeSchrittKategorie;

  /// No description provided for @qeSchrittZusatz.
  ///
  /// In de, this message translates to:
  /// **'Zusatzinfos'**
  String get qeSchrittZusatz;

  /// No description provided for @qeNameTitel.
  ///
  /// In de, this message translates to:
  /// **'Wie heißt der Ort?'**
  String get qeNameTitel;

  /// No description provided for @qeNameHint.
  ///
  /// In de, this message translates to:
  /// **'Name des Orts, z. B. Kinderarzt Müller'**
  String get qeNameHint;

  /// No description provided for @qeNamePflicht.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen ein.'**
  String get qeNamePflicht;

  /// No description provided for @qeTagHint.
  ///
  /// In de, this message translates to:
  /// **'Öffnungszeiten — bei Pausen einfach mehrere Blöcke anlegen.'**
  String get qeTagHint;

  /// No description provided for @qeGeoeffnet.
  ///
  /// In de, this message translates to:
  /// **'Geöffnet'**
  String get qeGeoeffnet;

  /// No description provided for @qeGleicheZeiten.
  ///
  /// In de, this message translates to:
  /// **'Gleiche Zeiten'**
  String get qeGleicheZeiten;

  /// No description provided for @qeGeschlossen.
  ///
  /// In de, this message translates to:
  /// **'Geschlossen'**
  String get qeGeschlossen;

  /// No description provided for @qeOeffnet.
  ///
  /// In de, this message translates to:
  /// **'öffnet'**
  String get qeOeffnet;

  /// No description provided for @qeSchliesst.
  ///
  /// In de, this message translates to:
  /// **'schließt'**
  String get qeSchliesst;

  /// No description provided for @qeWeitererBlock.
  ///
  /// In de, this message translates to:
  /// **'＋ weiterer Zeitblock'**
  String get qeWeitererBlock;

  /// No description provided for @qeBlockHint.
  ///
  /// In de, this message translates to:
  /// **'Die Lücke zwischen zwei Blöcken ist automatisch die Pause.'**
  String get qeBlockHint;

  /// No description provided for @qeBlockEntfernen.
  ///
  /// In de, this message translates to:
  /// **'Zeitblock entfernen'**
  String get qeBlockEntfernen;

  /// No description provided for @qeKategorieTitel.
  ///
  /// In de, this message translates to:
  /// **'Welche Kategorie?'**
  String get qeKategorieTitel;

  /// No description provided for @qeKategorieHint.
  ///
  /// In de, this message translates to:
  /// **'Für Gruppierung & Filter im Widget. Frei wählbar.'**
  String get qeKategorieHint;

  /// No description provided for @qeKategorieOhne.
  ///
  /// In de, this message translates to:
  /// **'Ohne Auswahl landet der Ort unter „Sonstige“.'**
  String get qeKategorieOhne;

  /// No description provided for @qeZusatzTitel.
  ///
  /// In de, this message translates to:
  /// **'Zusatzinfos'**
  String get qeZusatzTitel;

  /// No description provided for @qeZusatzHint.
  ///
  /// In de, this message translates to:
  /// **'Diese Felder sind optional. Du kannst sie später ergänzen.'**
  String get qeZusatzHint;

  /// No description provided for @qeAdresse.
  ///
  /// In de, this message translates to:
  /// **'Adresse'**
  String get qeAdresse;

  /// No description provided for @qeTelefon.
  ///
  /// In de, this message translates to:
  /// **'Telefonnummer'**
  String get qeTelefon;

  /// No description provided for @qeMapsLink.
  ///
  /// In de, this message translates to:
  /// **'Google Maps Link'**
  String get qeMapsLink;

  /// No description provided for @qeZurueck.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get qeZurueck;

  /// No description provided for @qeWeiter.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get qeWeiter;

  /// No description provided for @qeSpeichern.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get qeSpeichern;

  /// No description provided for @qeAbbrechen.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get qeAbbrechen;

  /// No description provided for @qeStartFrage.
  ///
  /// In de, this message translates to:
  /// **'Wie möchtest du den Ort anlegen?'**
  String get qeStartFrage;

  /// No description provided for @qeStartHinweis.
  ///
  /// In de, this message translates to:
  /// **'Am einfachsten übernimmst du einen echten Ort — Adresse und Öffnungszeiten kommen dann automatisch mit.'**
  String get qeStartHinweis;

  /// No description provided for @qeStartSuchenInfo.
  ///
  /// In de, this message translates to:
  /// **'Nach Name suchen, Daten aus OpenStreetMap übernehmen.'**
  String get qeStartSuchenInfo;

  /// No description provided for @qeStartUmkreisInfo.
  ///
  /// In de, this message translates to:
  /// **'Orte rund um deine Heimatadresse durchsuchen.'**
  String get qeStartUmkreisInfo;

  /// No description provided for @qeStartOder.
  ///
  /// In de, this message translates to:
  /// **'oder'**
  String get qeStartOder;

  /// No description provided for @qeManuell.
  ///
  /// In de, this message translates to:
  /// **'Manuell eingeben'**
  String get qeManuell;

  /// No description provided for @qeManuellInfo.
  ///
  /// In de, this message translates to:
  /// **'Name und Öffnungszeiten selbst eintippen.'**
  String get qeManuellInfo;

  /// No description provided for @valNameFehlt.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen ein.'**
  String get valNameFehlt;

  /// No description provided for @valKeinTagOffen.
  ///
  /// In de, this message translates to:
  /// **'Trage für mindestens einen Tag eine Öffnungszeit ein.'**
  String get valKeinTagOffen;

  /// No description provided for @valVonVorBis.
  ///
  /// In de, this message translates to:
  /// **'Die Öffnungszeit muss vor der Schließzeit liegen.'**
  String get valVonVorBis;

  /// No description provided for @valBloeckeUeberlappen.
  ///
  /// In de, this message translates to:
  /// **'Zeitblöcke dürfen sich nicht überschneiden.'**
  String get valBloeckeUeberlappen;

  /// No description provided for @valUngueltigeUrl.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine gültige URL ein (beginnt mit https://).'**
  String get valUngueltigeUrl;

  /// No description provided for @limitHinweis.
  ///
  /// In de, this message translates to:
  /// **'Maximale Anzahl von 50 Einträgen erreicht.'**
  String get limitHinweis;

  /// No description provided for @detailHeute.
  ///
  /// In de, this message translates to:
  /// **'heute'**
  String get detailHeute;

  /// No description provided for @detailBearbeiten.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get detailBearbeiten;

  /// No description provided for @detailLoeschen.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get detailLoeschen;

  /// No description provided for @detailInMapsOeffnen.
  ///
  /// In de, this message translates to:
  /// **'In Google Maps öffnen'**
  String get detailInMapsOeffnen;

  /// No description provided for @detailAdresse.
  ///
  /// In de, this message translates to:
  /// **'Adresse'**
  String get detailAdresse;

  /// No description provided for @detailTelefon.
  ///
  /// In de, this message translates to:
  /// **'Telefon'**
  String get detailTelefon;

  /// No description provided for @detailNichtGefunden.
  ///
  /// In de, this message translates to:
  /// **'Eintrag nicht gefunden'**
  String get detailNichtGefunden;

  /// No description provided for @geloescht.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ gelöscht'**
  String geloescht(String name);

  /// No description provided for @rueckgaengig.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get rueckgaengig;

  /// No description provided for @katNeuTitel.
  ///
  /// In de, this message translates to:
  /// **'Neue Kategorie'**
  String get katNeuTitel;

  /// No description provided for @katNeuHint.
  ///
  /// In de, this message translates to:
  /// **'Name und Farbe — frei wählbar.'**
  String get katNeuHint;

  /// No description provided for @katName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get katName;

  /// No description provided for @katFarbe.
  ///
  /// In de, this message translates to:
  /// **'Farbe'**
  String get katFarbe;

  /// No description provided for @katAnlegen.
  ///
  /// In de, this message translates to:
  /// **'Anlegen'**
  String get katAnlegen;

  /// No description provided for @katUmbenennen.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get katUmbenennen;

  /// No description provided for @katFarbeAendern.
  ///
  /// In de, this message translates to:
  /// **'Farbe ändern'**
  String get katFarbeAendern;

  /// No description provided for @katZusammenfuehren.
  ///
  /// In de, this message translates to:
  /// **'Mit anderer zusammenführen…'**
  String get katZusammenfuehren;

  /// No description provided for @katLoeschen.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get katLoeschen;

  /// No description provided for @katOrte.
  ///
  /// In de, this message translates to:
  /// **'{anzahl} Orte'**
  String katOrte(int anzahl);

  /// No description provided for @katEinOrt.
  ///
  /// In de, this message translates to:
  /// **'1 Ort'**
  String get katEinOrt;

  /// No description provided for @katSonstigeHint.
  ///
  /// In de, this message translates to:
  /// **'automatische Auffang-Kategorie'**
  String get katSonstigeHint;

  /// No description provided for @katLoeschenWarnung.
  ///
  /// In de, this message translates to:
  /// **'{anzahl} Orte fallen auf „Sonstige“ zurück.'**
  String katLoeschenWarnung(int anzahl);

  /// No description provided for @katZusammenWarnung.
  ///
  /// In de, this message translates to:
  /// **'Alle Orte aus „{von}“ wandern nach „{nach}“.'**
  String katZusammenWarnung(String von, String nach);

  /// No description provided for @katAendern.
  ///
  /// In de, this message translates to:
  /// **'Kategorie ändern'**
  String get katAendern;

  /// No description provided for @katZiel.
  ///
  /// In de, this message translates to:
  /// **'Ziel-Kategorie'**
  String get katZiel;

  /// No description provided for @katSpeichern.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get katSpeichern;

  /// No description provided for @katTitel.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get katTitel;

  /// No description provided for @urlKeinMapsLink.
  ///
  /// In de, this message translates to:
  /// **'Kein Google Maps Link gespeichert'**
  String get urlKeinMapsLink;

  /// No description provided for @urlKeinTelefon.
  ///
  /// In de, this message translates to:
  /// **'Kein Telefonwähler verfügbar'**
  String get urlKeinTelefon;

  /// No description provided for @urlFehler.
  ///
  /// In de, this message translates to:
  /// **'Konnte nicht geöffnet werden'**
  String get urlFehler;

  /// No description provided for @osmSuchen.
  ///
  /// In de, this message translates to:
  /// **'Ort aus dem Web übernehmen'**
  String get osmSuchen;

  /// No description provided for @osmManuell.
  ///
  /// In de, this message translates to:
  /// **'Manuell eintragen'**
  String get osmManuell;

  /// No description provided for @osmSuchTitel.
  ///
  /// In de, this message translates to:
  /// **'Ort suchen'**
  String get osmSuchTitel;

  /// No description provided for @osmSuchHint.
  ///
  /// In de, this message translates to:
  /// **'Name und Ort, z. B. „Apotheke Viersen“'**
  String get osmSuchHint;

  /// No description provided for @osmKeineTreffer.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer — bitte manuell eintragen.'**
  String get osmKeineTreffer;

  /// No description provided for @osmFehler.
  ///
  /// In de, this message translates to:
  /// **'Suche nicht möglich — bitte manuell eintragen.'**
  String get osmFehler;

  /// No description provided for @osmBestaetigeTitel.
  ///
  /// In de, this message translates to:
  /// **'Daten prüfen'**
  String get osmBestaetigeTitel;

  /// No description provided for @osmBestaetigeHint.
  ///
  /// In de, this message translates to:
  /// **'Daten aus dem Web — bitte prüfe, ob alles stimmt.'**
  String get osmBestaetigeHint;

  /// No description provided for @osmZeitenErkannt.
  ///
  /// In de, this message translates to:
  /// **'Öffnungszeiten erkannt — bitte prüfen'**
  String get osmZeitenErkannt;

  /// No description provided for @osmZeitenNichtErkannt.
  ///
  /// In de, this message translates to:
  /// **'Öffnungszeiten nicht erkannt — bitte manuell eintragen.'**
  String get osmZeitenNichtErkannt;

  /// No description provided for @osmUebernehmen.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get osmUebernehmen;

  /// No description provided for @widgetLeer.
  ///
  /// In de, this message translates to:
  /// **'Keine Einträge gespeichert — tippe hier, um zu starten'**
  String get widgetLeer;

  /// No description provided for @widgetKonfigTitel.
  ///
  /// In de, this message translates to:
  /// **'Widget einrichten'**
  String get widgetKonfigTitel;

  /// No description provided for @widgetKonfigFrage.
  ///
  /// In de, this message translates to:
  /// **'Welche Orte soll dieses Widget zeigen?'**
  String get widgetKonfigFrage;

  /// No description provided for @widgetHinzufuegen.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get widgetHinzufuegen;

  /// No description provided for @datenFehlerTitel.
  ///
  /// In de, this message translates to:
  /// **'Daten konnten nicht geladen werden'**
  String get datenFehlerTitel;

  /// No description provided for @datenFehlerText.
  ///
  /// In de, this message translates to:
  /// **'Die gespeicherten Daten waren beschädigt. Eine Sicherungskopie wurde angelegt, die App startet leer.'**
  String get datenFehlerText;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @speichernFehlgeschlagen.
  ///
  /// In de, this message translates to:
  /// **'Speichern fehlgeschlagen'**
  String get speichernFehlgeschlagen;

  /// No description provided for @exportTeilen.
  ///
  /// In de, this message translates to:
  /// **'Daten exportieren'**
  String get exportTeilen;

  /// No description provided for @menueSichern.
  ///
  /// In de, this message translates to:
  /// **'Sichern'**
  String get menueSichern;

  /// No description provided for @menueTeilen.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get menueTeilen;

  /// No description provided for @menueWiederherstellen.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get menueWiederherstellen;

  /// No description provided for @sichernBetreff.
  ///
  /// In de, this message translates to:
  /// **'WhenOpen-Sicherung'**
  String get sichernBetreff;

  /// No description provided for @sichernErfolg.
  ///
  /// In de, this message translates to:
  /// **'Gesichert in {ordner}. Die Datei ist unverschlüsselt und für andere Apps lesbar.'**
  String sichernErfolg(String ordner);

  /// No description provided for @sichernKeineBerechtigung.
  ///
  /// In de, this message translates to:
  /// **'Bitte Speicher-Berechtigung erteilen und erneut sichern.'**
  String get sichernKeineBerechtigung;

  /// No description provided for @sichernFehler.
  ///
  /// In de, this message translates to:
  /// **'Sichern fehlgeschlagen'**
  String get sichernFehler;

  /// No description provided for @teilenFehler.
  ///
  /// In de, this message translates to:
  /// **'Teilen fehlgeschlagen'**
  String get teilenFehler;

  /// No description provided for @wiederherstellenTitel.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen?'**
  String get wiederherstellenTitel;

  /// No description provided for @wiederherstellenLetzte.
  ///
  /// In de, this message translates to:
  /// **'Letzte Sicherung laden'**
  String get wiederherstellenLetzte;

  /// No description provided for @wiederherstellenLetzteInfo.
  ///
  /// In de, this message translates to:
  /// **'Aus dem Ordner Download/WhenOpen'**
  String get wiederherstellenLetzteInfo;

  /// No description provided for @wiederherstellenDatei.
  ///
  /// In de, this message translates to:
  /// **'Datei wählen…'**
  String get wiederherstellenDatei;

  /// No description provided for @wiederherstellenDateiInfo.
  ///
  /// In de, this message translates to:
  /// **'Aus Dateien, Downloads oder einer empfangenen Nachricht'**
  String get wiederherstellenDateiInfo;

  /// No description provided for @wiederherstellenKeine.
  ///
  /// In de, this message translates to:
  /// **'Keine Sicherung im Ordner Download/WhenOpen gefunden.'**
  String get wiederherstellenKeine;

  /// No description provided for @wiederherstellenVorschau.
  ///
  /// In de, this message translates to:
  /// **'Diese Sicherung enthält {orte, plural, =0{keine Orte} =1{1 Ort} other{{orte} Orte}} und {kategorien, plural, =0{keine Kategorien} =1{1 Kategorie} other{{kategorien} Kategorien}}.'**
  String wiederherstellenVorschau(int orte, int kategorien);

  /// No description provided for @wiederherstellenWarnung.
  ///
  /// In de, this message translates to:
  /// **'Deine jetzigen {anzahl, plural, =0{Daten} =1{1 Ort} other{{anzahl} Orte}} werden vorher automatisch gesichert.'**
  String wiederherstellenWarnung(int anzahl);

  /// No description provided for @wiederherstellenAktion.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get wiederherstellenAktion;

  /// No description provided for @wiederherstellenErfolg.
  ///
  /// In de, this message translates to:
  /// **'Daten wiederhergestellt.'**
  String get wiederherstellenErfolg;

  /// No description provided for @wiederherstellenFehler.
  ///
  /// In de, this message translates to:
  /// **'Keine gültige WhenOpen-Sicherung — nichts geändert.'**
  String get wiederherstellenFehler;

  /// No description provided for @abbrechen.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get abbrechen;

  /// No description provided for @menueEinstellungen.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get menueEinstellungen;

  /// No description provided for @einstTitel.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get einstTitel;

  /// No description provided for @einstHeimatTitel.
  ///
  /// In de, this message translates to:
  /// **'Heimatadresse'**
  String get einstHeimatTitel;

  /// No description provided for @einstHeimatInfo.
  ///
  /// In de, this message translates to:
  /// **'Für die Umkreissuche „Orte in der Nähe“. Wird einmalig zu Koordinaten aufgelöst und bleibt lokal — keine Standortfreigabe nötig.'**
  String get einstHeimatInfo;

  /// No description provided for @einstHeimatKeine.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Heimatadresse hinterlegt.'**
  String get einstHeimatKeine;

  /// No description provided for @einstHeimatSuchen.
  ///
  /// In de, this message translates to:
  /// **'Adresse suchen'**
  String get einstHeimatSuchen;

  /// No description provided for @einstHeimatSuchHint.
  ///
  /// In de, this message translates to:
  /// **'Straße und Ort, z. B. „Hauptstraße 1, Köln“'**
  String get einstHeimatSuchHint;

  /// No description provided for @einstHeimatEntfernen.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get einstHeimatEntfernen;

  /// No description provided for @einstUmkreisTitel.
  ///
  /// In de, this message translates to:
  /// **'Suchradius'**
  String get einstUmkreisTitel;

  /// No description provided for @einstUmkreisMeter.
  ///
  /// In de, this message translates to:
  /// **'{meter} m'**
  String einstUmkreisMeter(int meter);

  /// No description provided for @einstUmkreisKm.
  ///
  /// In de, this message translates to:
  /// **'{km} km'**
  String einstUmkreisKm(String km);

  /// No description provided for @einstSpeichern.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get einstSpeichern;

  /// No description provided for @einstGespeichert.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen gespeichert.'**
  String get einstGespeichert;

  /// No description provided for @einstAttribution.
  ///
  /// In de, this message translates to:
  /// **'Ortsdaten: © OpenStreetMap-Mitwirkende (ODbL)'**
  String get einstAttribution;

  /// No description provided for @umkreisSuchen.
  ///
  /// In de, this message translates to:
  /// **'Orte in der Nähe'**
  String get umkreisSuchen;

  /// No description provided for @umkreisTitel.
  ///
  /// In de, this message translates to:
  /// **'Orte in der Nähe'**
  String get umkreisTitel;

  /// No description provided for @umkreisRadiusInfo.
  ///
  /// In de, this message translates to:
  /// **'{radius} um {adresse}'**
  String umkreisRadiusInfo(String radius, String adresse);

  /// No description provided for @umkreisLaedt.
  ///
  /// In de, this message translates to:
  /// **'Suche Orte in deiner Nähe…'**
  String get umkreisLaedt;

  /// No description provided for @umkreisKeineTreffer.
  ///
  /// In de, this message translates to:
  /// **'Keine Orte mit Öffnungszeiten im Umkreis gefunden. Erhöhe ggf. den Radius in den Einstellungen.'**
  String get umkreisKeineTreffer;

  /// No description provided for @umkreisFehler.
  ///
  /// In de, this message translates to:
  /// **'Suche nicht möglich — bitte später erneut versuchen.'**
  String get umkreisFehler;

  /// No description provided for @umkreisKeineHeimat.
  ///
  /// In de, this message translates to:
  /// **'Hinterlege zuerst deine Heimatadresse in den Einstellungen.'**
  String get umkreisKeineHeimat;

  /// No description provided for @umkreisZuEinstellungen.
  ///
  /// In de, this message translates to:
  /// **'Zu den Einstellungen'**
  String get umkreisZuEinstellungen;

  /// No description provided for @menueUeber.
  ///
  /// In de, this message translates to:
  /// **'Über WhenOpen'**
  String get menueUeber;

  /// No description provided for @ueberTitel.
  ///
  /// In de, this message translates to:
  /// **'Über WhenOpen'**
  String get ueberTitel;

  /// No description provided for @ueberTagline.
  ///
  /// In de, this message translates to:
  /// **'Persönliche Öffnungszeiten auf einen Blick.'**
  String get ueberTagline;

  /// No description provided for @ueberUnterstuetzenTitel.
  ///
  /// In de, this message translates to:
  /// **'Unterstützen'**
  String get ueberUnterstuetzenTitel;

  /// No description provided for @ueberUnterstuetzenHinweis.
  ///
  /// In de, this message translates to:
  /// **'WhenOpen ist und bleibt kostenlos — es schaltet nichts frei.'**
  String get ueberUnterstuetzenHinweis;

  /// No description provided for @ueberKaffeeButton.
  ///
  /// In de, this message translates to:
  /// **'Spendier mir einen Kaffee ☕'**
  String get ueberKaffeeButton;

  /// No description provided for @ueberLinkFehler.
  ///
  /// In de, this message translates to:
  /// **'Link konnte nicht geöffnet werden.'**
  String get ueberLinkFehler;

  /// No description provided for @ueberVersion.
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String ueberVersion(String version);

  /// No description provided for @ueberKontaktTitel.
  ///
  /// In de, this message translates to:
  /// **'Kontakt & Feedback'**
  String get ueberKontaktTitel;

  /// No description provided for @ueberKontaktHinweis.
  ///
  /// In de, this message translates to:
  /// **'Fragen, Wünsche oder ein Fehler aufgetaucht? Ich freue mich über deine Nachricht.'**
  String get ueberKontaktHinweis;

  /// No description provided for @ueberKontaktButton.
  ///
  /// In de, this message translates to:
  /// **'E-Mail schreiben'**
  String get ueberKontaktButton;

  /// No description provided for @ueberKontaktBetreff.
  ///
  /// In de, this message translates to:
  /// **'WhenOpen-Feedback'**
  String get ueberKontaktBetreff;

  /// No description provided for @tutorialDialogTitel.
  ///
  /// In de, this message translates to:
  /// **'Kurze Einführung?'**
  String get tutorialDialogTitel;

  /// No description provided for @tutorialDialogText.
  ///
  /// In de, this message translates to:
  /// **'Es sieht aus, als wärst du neu hier. Möchtest du eine kurze Tour durch WhenOpen — Kategorien, Daten und „Orte in der Nähe“?'**
  String get tutorialDialogText;

  /// No description provided for @tutorialDialogJa.
  ///
  /// In de, this message translates to:
  /// **'Tour starten'**
  String get tutorialDialogJa;

  /// No description provided for @tutorialDialogNein.
  ///
  /// In de, this message translates to:
  /// **'Nein, danke'**
  String get tutorialDialogNein;

  /// No description provided for @onboardingUeberspringen.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get onboardingUeberspringen;

  /// No description provided for @onboardingWeiter.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get onboardingWeiter;

  /// No description provided for @onboardingErsterOrt.
  ///
  /// In de, this message translates to:
  /// **'Ersten Ort anlegen'**
  String get onboardingErsterOrt;

  /// No description provided for @onboardingFertig.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get onboardingFertig;

  /// No description provided for @onboardingWillkommenTitel.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei WhenOpen'**
  String get onboardingWillkommenTitel;

  /// No description provided for @onboardingWillkommenText.
  ///
  /// In de, this message translates to:
  /// **'Behalte die Öffnungszeiten deiner wichtigen Orte im Blick. Alles bleibt lokal auf deinem Gerät — kein Konto, keine Cloud, kein Tracking.'**
  String get onboardingWillkommenText;

  /// No description provided for @onboardingKategorienTitel.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get onboardingKategorienTitel;

  /// No description provided for @onboardingKategorienText.
  ///
  /// In de, this message translates to:
  /// **'Ordne deine Orte in frei wählbare Kategorien wie „Ärzte“ oder „Einkaufen“ — praktisch zum Gruppieren und Filtern. Ohne Auswahl landet ein Ort unter „Sonstige“.'**
  String get onboardingKategorienText;

  /// No description provided for @onboardingDatenTitel.
  ///
  /// In de, this message translates to:
  /// **'Woher kommen die Daten?'**
  String get onboardingDatenTitel;

  /// No description provided for @onboardingDatenText.
  ///
  /// In de, this message translates to:
  /// **'Du kannst Orte aus dem Web übernehmen (OpenStreetMap), „Orte in der Nähe“ suchen oder Zeiten von Hand eintragen. Deine Sammlung lässt sich jederzeit sichern und wiederherstellen.'**
  String get onboardingDatenText;

  /// No description provided for @onboardingAdresseTitel.
  ///
  /// In de, this message translates to:
  /// **'Deine Adresse (einmalig)'**
  String get onboardingAdresseTitel;

  /// No description provided for @onboardingAdresseText.
  ///
  /// In de, this message translates to:
  /// **'Damit du kein GPS nutzen musst, fragen wir einmal nach deiner Adresse. Ohne Adresse wird die Funktion „Orte in der Nähe“ nicht freigeschaltet.'**
  String get onboardingAdresseText;

  /// No description provided for @onboardingAdresseGesetzt.
  ///
  /// In de, this message translates to:
  /// **'Super — „Orte in der Nähe“ ist jetzt freigeschaltet.'**
  String get onboardingAdresseGesetzt;

  /// No description provided for @onboardingWidgetTitel.
  ///
  /// In de, this message translates to:
  /// **'Das Herzstück: das Widget'**
  String get onboardingWidgetTitel;

  /// No description provided for @onboardingWidgetText.
  ///
  /// In de, this message translates to:
  /// **'WhenOpen spielt seine Stärke erst auf dem Startbildschirm aus: Das Widget zeigt dir auf einen Blick, welche Orte gerade geöffnet sind — ganz ohne die App zu öffnen. Richtig nützlich wird die App also erst, wenn du das Widget anlegst.'**
  String get onboardingWidgetText;

  /// No description provided for @onboardingWidgetSchritt1.
  ///
  /// In de, this message translates to:
  /// **'Tippe lange auf eine freie Stelle des Startbildschirms.'**
  String get onboardingWidgetSchritt1;

  /// No description provided for @onboardingWidgetSchritt2.
  ///
  /// In de, this message translates to:
  /// **'Wähle „Widgets“ und suche WhenOpen.'**
  String get onboardingWidgetSchritt2;

  /// No description provided for @onboardingWidgetSchritt3.
  ///
  /// In de, this message translates to:
  /// **'Zieh das Widget auf den Startbildschirm — fertig.'**
  String get onboardingWidgetSchritt3;

  /// No description provided for @onboardingFertigTitel.
  ///
  /// In de, this message translates to:
  /// **'Los geht’s!'**
  String get onboardingFertigTitel;

  /// No description provided for @onboardingFertigText.
  ///
  /// In de, this message translates to:
  /// **'Du bist startklar. Am einfachsten legst du deinen ersten Ort über „Orte in der Nähe“ an — und denk ans Widget auf dem Startbildschirm.'**
  String get onboardingFertigText;

  /// No description provided for @tutorialQeHinweis.
  ///
  /// In de, this message translates to:
  /// **'Tipp: Über „Orte in der Nähe“ findest du einen Ort automatisch — Name, Adresse und Öffnungszeiten werden direkt übernommen.'**
  String get tutorialQeHinweis;

  /// No description provided for @spendeDialogTitel.
  ///
  /// In de, this message translates to:
  /// **'Gefällt dir WhenOpen?'**
  String get spendeDialogTitel;

  /// No description provided for @spendeDialogText.
  ///
  /// In de, this message translates to:
  /// **'Du hast schon {anzahl} Orte gespeichert — schön, dass dir die App hilft! Sie ist und bleibt kostenlos. Wenn du magst, spendier mir einen Kaffee oder schick mir kurz Feedback.'**
  String spendeDialogText(int anzahl);

  /// No description provided for @spendeDialogFeedback.
  ///
  /// In de, this message translates to:
  /// **'Feedback'**
  String get spendeDialogFeedback;

  /// No description provided for @spendeDialogSpaeter.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get spendeDialogSpaeter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
