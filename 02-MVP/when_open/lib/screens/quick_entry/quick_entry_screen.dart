import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locations_provider.dart';
import '../../services/validation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kategorie_dialog.dart';
import 'kategorie_step.dart';
import 'name_step.dart';
import 'optional_fields_step.dart';
import 'osm_search_step.dart';
import 'quick_entry_state.dart';
import 'start_auswahl_step.dart';
import 'umkreis_search_step.dart';
import 'week_hours_step.dart';

/// Schnelleintrag-Flow (Workflow 1): 10 Schritte —
/// Name · Mo–So (Mehrblock-Editor, E9) · Kategorie (E15) · Zusatzinfos.
/// Mit `editId` laeuft derselbe Flow als Bearbeiten (P05).
class QuickEntryScreen extends ConsumerStatefulWidget {
  const QuickEntryScreen({
    super.key,
    this.editId,
    this.kategorieId,
    this.tutorial = false,
  });

  final String? editId;
  final String? kategorieId;

  /// Aus dem Erstnutzer-Tutorial geoeffnet: blendet im ersten Schritt einen
  /// Hinweis zu „Orte in der Nähe" ein.
  final bool tutorial;

  @override
  ConsumerState<QuickEntryScreen> createState() => _QuickEntryScreenState();
}

class _QuickEntryScreenState extends ConsumerState<QuickEntryScreen> {
  late final QuickEntryState _state;
  late final TextEditingController _nameController;
  late final TextEditingController _adresseController;
  late final TextEditingController _telefonController;
  late final TextEditingController _mapsLinkController;

  bool _zeigeNameFehler = false;
  bool _zeigeUrlFehler = false;

  /// Punkt 1: Beim Anlegen erscheint zuerst die Methodenauswahl (lokal =
  /// Standard); erst danach das Namensfeld. Beim Bearbeiten entfällt sie.
  bool _zeigeStartAuswahl = false;

  /// Tastatur nur dann sofort öffnen, wenn der Nutzer „Manuell" gewählt hat.
  bool _nameAutofokus = false;

  @override
  void initState() {
    super.initState();
    final editId = widget.editId;
    if (editId != null) {
      final vorhandene = ref
          .read(locationsProvider)
          .where((l) => l.id == editId)
          .toList();
      _state = vorhandene.isNotEmpty
          ? QuickEntryState.fromLocation(vorhandene.single)
          : QuickEntryState();
    } else {
      _state = QuickEntryState();
      _state.kategorieId = widget.kategorieId;
      _zeigeStartAuswahl = true;
    }
    _nameController = TextEditingController(text: _state.name);
    _adresseController = TextEditingController(text: _state.adresse);
    _telefonController = TextEditingController(text: _state.telefon);
    _mapsLinkController = TextEditingController(text: _state.googleMapsLink);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _adresseController.dispose();
    _telefonController.dispose();
    _mapsLinkController.dispose();
    super.dispose();
  }

  void _uebernehmeFelder() {
    _state.name = _nameController.text;
    _state.adresse = _adresseController.text;
    _state.telefon = _telefonController.text;
    _state.googleMapsLink = _mapsLinkController.text;
  }

  void _weiter() {
    _uebernehmeFelder();
    if (_state.aktuellerSchritt == 0 && _state.name.trim().isEmpty) {
      setState(() => _zeigeNameFehler = true);
      return;
    }
    if (_state.istLetzterSchritt) {
      _speichern();
      return;
    }
    setState(() {
      _zeigeNameFehler = false;
      _state.aktuellerSchritt++;
    });
  }

  void _zurueck() {
    if (_state.aktuellerSchritt == 0) {
      // Aus dem Namensfeld zurück zur Methodenauswahl (nur Neuanlage);
      // aus der Auswahl bzw. beim Bearbeiten den Screen verlassen.
      if (!_zeigeStartAuswahl && !_state.istBearbeiten) {
        setState(() => _zeigeStartAuswahl = true);
        return;
      }
      context.pop();
      return;
    }
    _uebernehmeFelder();
    setState(() => _state.aktuellerSchritt--);
  }

  /// „Manuell eingeben" gewählt: Namensfeld zeigen und Tastatur öffnen.
  void _waehleManuell() {
    setState(() {
      _zeigeStartAuswahl = false;
      _nameAutofokus = true;
    });
  }

  Future<void> _speichern() async {
    final l10n = AppLocalizations.of(context)!;
    final location = _state.toLocation();
    final fehler = ValidationService.validateLocation(location);

    if (fehler.isNotEmpty) {
      final erster = fehler.first;
      setState(() {
        _zeigeNameFehler =
            fehler.any((f) => f.typ == ValidationFehlerTyp.nameFehlt);
        _zeigeUrlFehler =
            fehler.any((f) => f.typ == ValidationFehlerTyp.ungueltigeUrl);
        // Zum betroffenen Schritt springen
        if (_zeigeNameFehler) {
          _state.aktuellerSchritt = 0;
        } else if (erster.typ == ValidationFehlerTyp.keinTagGeoeffnet ||
            erster.typ == ValidationFehlerTyp.vonNachBis ||
            erster.typ == ValidationFehlerTyp.bloeckeUeberlappen) {
          _state.aktuellerSchritt = 1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erster.meldung(l10n))),
      );
      return;
    }

    final notifier = ref.read(appDataProvider.notifier);
    final anzahlVorher = ref.read(locationsProvider).length;
    if (_state.istBearbeiten) {
      await notifier.updateLocation(location);
    } else {
      await notifier.addLocation(location);
    }

    if (!mounted) return;
    // E11: weicher Hinweis ab 50 Eintraegen — kein harter Block.
    if (!_state.istBearbeiten && anzahlVorher + 1 >= 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.limitHinweis)),
      );
    }
    context.pop();
  }

  /// P08b: Textsuche → Bestaetigung → Felder vorbefuellen. Der Nutzer laeuft
  /// danach normal durch den Flow und kann alles anpassen.
  Future<void> _osmImport() async {
    final uebernahme = await Navigator.of(context).push<OsmUebernahme>(
      MaterialPageRoute(builder: (_) => const OsmSearchStep()),
    );
    _wendeUebernahmeAn(uebernahme);
  }

  /// „Orte in der Nähe": Umkreissuche um die hinterlegte Heimatadresse.
  /// Ohne Heimatadresse → Hinweis mit Sprung in die Einstellungen.
  Future<void> _umkreisImport() async {
    final l10n = AppLocalizations.of(context)!;
    if (!ref.read(einstellungenProvider).hatHeimat) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.umkreisKeineHeimat),
        action: SnackBarAction(
          label: l10n.umkreisZuEinstellungen,
          onPressed: () => context.push('/einstellungen'),
        ),
      ));
      return;
    }
    final uebernahme = await Navigator.of(context).push<OsmUebernahme>(
      MaterialPageRoute(builder: (_) => const UmkreisSearchStep()),
    );
    _wendeUebernahmeAn(uebernahme);
  }

  /// Uebernimmt die bestaetigten Web-/Umkreis-Daten in den Flow-Zustand.
  /// Verlässt die Methodenauswahl und zeigt das (vorbefüllte) Namensfeld OHNE
  /// Tastatur — der Nutzer prüft nur noch.
  void _wendeUebernahmeAn(OsmUebernahme? uebernahme) {
    if (uebernahme == null || !mounted) return;
    setState(() {
      _zeigeStartAuswahl = false;
      _nameAutofokus = false;
      _nameController.text = uebernahme.name;
      if (uebernahme.adresse != null) {
        _adresseController.text = uebernahme.adresse!;
      }
      if (uebernahme.telefon != null) {
        _telefonController.text = uebernahme.telefon!;
      }
      final zeiten = uebernahme.zeiten;
      if (zeiten != null) {
        for (final tag in zeiten) {
          _state.zeiten[tag.wochentag] = [...tag.zeiten];
          // Nur Tage MIT erkannten Zeiten gelten als festgelegt; leere bleiben
          // „noch festlegen" (keine stille Geschlossen-Annahme bei OSM-Lücken).
          if (tag.zeiten.isNotEmpty) {
            _state.festgelegt.add(tag.wochentag);
          }
        }
      }
      _zeigeNameFehler = false;
    });
  }

  Future<void> _neueKategorie() async {
    final ergebnis = await zeigeNeueKategorieDialog(context);
    if (ergebnis == null) return;
    final kategorie = await ref
        .read(appDataProvider.notifier)
        .addKategorie(ergebnis.name, farbe: ergebnis.farbe);
    setState(() => _state.kategorieId = kategorie.id);
  }

  String _schrittLabel(AppLocalizations l10n) {
    final schritt = _state.aktuellerSchritt;
    final name = switch (schritt) {
      0 => l10n.qeSchrittName,
      1 => l10n.qeSchrittZeiten,
      2 => l10n.qeSchrittKategorie,
      _ => l10n.qeSchrittZusatz,
    };
    return '${l10n.qeSchritt(schritt + 1, QuickEntryState.schritteGesamt)} · $name';
  }

  Widget _aktuellerStep() {
    final schritt = _state.aktuellerSchritt;
    if (schritt == 0) {
      return NameStep(
        controller: _nameController,
        zeigeFehler: _zeigeNameFehler,
        autofocus: _nameAutofokus,
        onWeiter: _weiter,
      );
    }
    if (schritt == 1) {
      return WeekHoursStep(
        state: _state,
        onChanged: () => setState(() {}),
      );
    }
    if (schritt == 2) {
      return KategorieStep(
        kategorien: ref.watch(kategorienProvider),
        gewaehlteId: _state.kategorieId,
        onGewaehlt: (id) => setState(() => _state.kategorieId = id),
        onNeueKategorie: _neueKategorie,
      );
    }
    return OptionalFieldsStep(
      adresseController: _adresseController,
      telefonController: _telefonController,
      mapsLinkController: _mapsLinkController,
      zeigeUrlFehler: _zeigeUrlFehler,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fortschritt =
        (_state.aktuellerSchritt + 1) / QuickEntryState.schritteGesamt;
    final zeigeAuswahl = _zeigeStartAuswahl &&
        _state.aktuellerSchritt == 0 &&
        !_state.istBearbeiten;

    return Scaffold(
      appBar: AppBar(
        title: Text(_state.istBearbeiten ? l10n.qeBearbeiten : l10n.qeNeuerOrt),
        leading: BackButton(onPressed: _zurueck),
      ),
      body: SafeArea(
        child: zeigeAuswahl
            ? Column(
                children: [
                  if (widget.tutorial)
                    _TutorialHinweis(text: l10n.tutorialQeHinweis),
                  Expanded(
                    child: StartAuswahlStep(
                      onSuchen: _osmImport,
                      onUmkreis: _umkreisImport,
                      onManuell: _waehleManuell,
                    ),
                  ),
                ],
              )
            : Column(
          children: [
            // Fortschrittsbalken + Schrittanzeige (Mockup: stepbar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fortschritt,
                      minHeight: 6,
                      backgroundColor: AppColors.line,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(_schrittLabel(l10n),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            const Divider(height: 16),
            if (widget.tutorial &&
                !_state.istBearbeiten &&
                _state.aktuellerSchritt == 0)
              _TutorialHinweis(text: l10n.tutorialQeHinweis),
            Expanded(child: _aktuellerStep()),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _zurueck,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        backgroundColor: AppColors.chip,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                          _state.aktuellerSchritt == 0 && _state.istBearbeiten
                              ? l10n.qeAbbrechen
                              : l10n.qeZurueck),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _weiter,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(_state.istLetzterSchritt
                          ? l10n.qeSpeichern
                          : l10n.qeWeiter),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dezenter Hinweis-Banner im gefuehrten Erst-Eintrag (Tutorial).
class _TutorialHinweis extends StatelessWidget {
  const _TutorialHinweis({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline,
              size: 18, color: context.col.primaryInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.35, color: context.col.ink),
            ),
          ),
        ],
      ),
    );
  }
}
