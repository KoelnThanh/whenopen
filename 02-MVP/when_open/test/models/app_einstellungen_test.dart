import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/models/app_einstellungen.dart';

void main() {
  group('AppEinstellungen', () {
    test('Standard-Suchradius ist 1 km (1000 m)', () {
      expect(AppEinstellungen.standardUmkreis, 1000);
      expect(const AppEinstellungen().umkreisMeter, 1000);
    });

    test('Default-Tutorialstatus ist offen', () {
      expect(const AppEinstellungen().tutorialStatus, TutorialStatus.offen);
    });

    test('toJson/fromJson Roundtrip bewahrt tutorialStatus', () {
      const einst = AppEinstellungen(
        heimatAdresse: 'Domkloster 4, Köln',
        heimatLat: 50.94,
        heimatLon: 6.96,
        umkreisMeter: 1500,
        tutorialStatus: TutorialStatus.abgeschlossen,
      );
      final zurueck = AppEinstellungen.fromJson(einst.toJson());
      expect(zurueck.heimatAdresse, 'Domkloster 4, Köln');
      expect(zurueck.heimatLat, 50.94);
      expect(zurueck.umkreisMeter, 1500);
      expect(zurueck.tutorialStatus, TutorialStatus.abgeschlossen);
    });

    test('fromJson ohne tutorial_status → offen (Migration alter Dateien)', () {
      final einst = AppEinstellungen.fromJson({
        'heimat_lat': 1.0,
        'heimat_lon': 2.0,
        'umkreis_meter': 800,
      });
      expect(einst.tutorialStatus, TutorialStatus.offen);
      expect(einst.umkreisMeter, 800);
    });

    test('fromJson mit unbekanntem tutorial_status → offen', () {
      final einst =
          AppEinstellungen.fromJson({'tutorial_status': 'irgendwas'});
      expect(einst.tutorialStatus, TutorialStatus.offen);
    });

    test('copyWith bewahrt tutorialStatus beim Aendern anderer Felder', () {
      const einst = AppEinstellungen(tutorialStatus: TutorialStatus.abgelehnt);
      final neu = einst.copyWith(umkreisMeter: 2000);
      expect(neu.umkreisMeter, 2000);
      expect(neu.tutorialStatus, TutorialStatus.abgelehnt);
    });

    test('copyWith aktualisiert tutorialStatus', () {
      const einst = AppEinstellungen();
      final neu = einst.copyWith(tutorialStatus: TutorialStatus.abgeschlossen);
      expect(neu.tutorialStatus, TutorialStatus.abgeschlossen);
    });
  });
}
