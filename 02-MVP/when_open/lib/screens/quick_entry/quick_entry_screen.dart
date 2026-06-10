import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locations_provider.dart';
import '../../services/open_status_service.dart';
import '../../services/validation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kategorie_dialog.dart';
import 'day_entry_step.dart';
import 'kategorie_step.dart';
import 'name_step.dart';
import 'optional_fields_step.dart';
import 'osm_search_step.dart';
import 'quick_entry_state.dart';

/// Schnelleintrag-Flow (Workflow 1): 10 Schritte —
/// Name · Mo–So (Mehrblock-Editor, E9) · Kategorie (E15) · Zusatzinfos.
/// Mit `editId` laeuft derselbe Flow als Bearbeiten (P05).
class QuickEntryScreen extends ConsumerStatefulWidget {
  const QuickEntryScreen({super.key, this.editId, this.kategorieId});

  final String? editId;
  final String? kategorieId;

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
      context.pop();
      return;
    }
    _uebernehmeFelder();
    setState(() => _state.aktuellerSchritt--);
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

  /// P08b: Suche → Bestaetigung → Felder vorbefuellen. Der Nutzer laeuft
  /// danach normal durch den Flow und kann alles anpassen.
  Future<void> _osmImport() async {
    final uebernahme = await Navigator.of(context).push<OsmUebernahme>(
      MaterialPageRoute(builder: (_) => const OsmSearchStep()),
    );
    if (uebernahme == null || !mounted) return;
    setState(() {
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
      >= 1 && <= 7 => OpenStatusService.wochentagLang(
          _state.aktuellerWochentag, l10n),
      8 => l10n.qeSchrittKategorie,
      _ => l10n.qeSchrittZusatz,
    };
    return '${l10n.qeSchritt(schritt + 1, QuickEntryState.schritteGesamt)} · $name';
  }

  Widget _aktuellerStep() {
    final l10n = AppLocalizations.of(context)!;
    final schritt = _state.aktuellerSchritt;
    if (schritt == 0) {
      return NameStep(
        controller: _nameController,
        zeigeFehler: _zeigeNameFehler,
        onWeiter: _weiter,
        // Import nur bei Neuanlage — beim Bearbeiten irrefuehrend.
        onOsmImport: _state.istBearbeiten ? null : _osmImport,
      );
    }
    if (schritt >= 1 && schritt <= 7) {
      final tag = _state.aktuellerWochentag;
      return DayEntryStep(
        key: ValueKey(tag),
        tagName: OpenStatusService.wochentagLang(tag, l10n),
        bloecke: _state.zeiten[tag]!,
        vorschlag: _state.vorschlagFuer(tag),
        onChanged: (bloecke) =>
            setState(() => _state.zeiten[tag] = bloecke),
      );
    }
    if (schritt == 8) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_state.istBearbeiten ? l10n.qeBearbeiten : l10n.qeNeuerOrt),
        leading: BackButton(onPressed: _zurueck),
      ),
      body: SafeArea(
        child: Column(
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
                      child: Text(_state.aktuellerSchritt == 0
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
