import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/kategorie.dart';
import '../models/location.dart';
import '../providers/locations_provider.dart';
import '../services/open_status_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kategorie_dialog.dart';
import '../widgets/kategorie_sheets.dart';
import '../widgets/location_list_tile.dart';
import '../widgets/undo_delete.dart';

/// Hauptliste (Workflow 3, E10): nach Kategorie gruppiert, Umschalten ueber
/// Bottom-Umschalter + Auswahl-Sheet (Google-Tasks-Stil), Wischen blaettert.
/// v0.3: Hero-Header (Marke + Datum + „X offen"-Uebersicht) statt AppBar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// Eine "Ansicht" = eine Seite im PageView.
/// kategorieId: null = Alle Orte, '' = Sonstige, sonst echte Kategorie-ID.
class _Ansicht {
  const _Ansicht.alle() : kategorieId = null, kategorie = null;
  const _Ansicht.sonstige() : kategorieId = '', kategorie = null;
  const _Ansicht.fuer(Kategorie this.kategorie) : kategorieId = null;

  final Kategorie? kategorie;
  final String? kategorieId;

  bool get istAlle => kategorie == null && kategorieId == null;
  bool get istSonstige => kategorieId == '';

  String label(AppLocalizations l10n) => istAlle
      ? l10n.alleOrte
      : istSonstige
      ? l10n.sonstige
      : kategorie!.name;

  Color? punktFarbe() => istAlle
      ? null
      : istSonstige
      ? AppColors.kategorieFallback
      : farbeAusHex(kategorie!.farbe);

  bool enthaelt(Location location) => istAlle
      ? true
      : istSonstige
      ? location.kategorie == null
      : location.kategorie == kategorie!.id;
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  int _seite = 0;
  DateTime _jetzt = DateTime.now();
  Timer? _timer;
  bool _ladefehlerGezeigt = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // E16: beim Zurueckkehren in den Vordergrund neu rechnen.
    if (state == AppLifecycleState.resumed) {
      setState(() => _jetzt = DateTime.now());
    }
  }

  /// E16 in der App: genau ein Timer auf die naechste Block-Grenze —
  /// kein Minuten-Polling.
  void _planeNaechsteAktualisierung(List<Location> locations) {
    _timer?.cancel();
    final naechste = OpenStatusService.naechsteAenderung(
      locations,
      DateTime.now(),
    );
    final dauer = naechste.difference(DateTime.now());
    _timer = Timer(dauer.isNegative ? const Duration(seconds: 1) : dauer, () {
      if (!mounted) return;
      setState(() => _jetzt = DateTime.now());
    });
  }

  Future<void> _zeigeLadefehlerFallsNoetig() async {
    if (_ladefehlerGezeigt) return;
    _ladefehlerGezeigt = true;
    final hatteFehler = await ref
        .read(appDataProvider.notifier)
        .hatteLadefehler();
    if (!hatteFehler || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.datenFehlerTitel),
        content: Text(l10n.datenFehlerText),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  List<_Ansicht> _ansichten(
    List<Kategorie> kategorien,
    List<Location> locations,
  ) {
    return [
      const _Ansicht.alle(),
      for (final kategorie in kategorien) _Ansicht.fuer(kategorie),
      if (kategorien.isNotEmpty && locations.any((l) => l.kategorie == null))
        const _Ansicht.sonstige(),
    ];
  }

  void _geheZuSeite(int seite) {
    setState(() => _seite = seite);
    _pageController.animateToPage(
      seite,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _neuerEintrag(_Ansicht ansicht) {
    // Aktiven Kategorie-Filter vorbelegen (E10).
    final kategorie = ansicht.kategorie;
    final query = kategorie != null ? '?kategorie=${kategorie.id}' : '';
    context.push('/quick-entry$query');
  }

  Future<void> _suche(List<Location> locations, AppLocalizations l10n) async {
    final id = await showSearch<String?>(
      context: context,
      delegate: _OrtSuche(
        locations: locations,
        jetzt: _jetzt,
        hint: l10n.sucheHint,
        keineTreffer: l10n.keineTreffer,
      ),
    );
    if (id != null && mounted && context.mounted) {
      context.push('/detail/$id');
    }
  }

  /// Daten sichern: datierte JSON-Kopie über den Teilen-Dialog ausgeben
  /// (Drive, E-Mail, Dateien …) — die Absicherung gegen Datenverlust.
  Future<void> _sichern() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final datei = await ref.read(appDataProvider.notifier).exportKopie();
      await Share.shareXFiles(
        [XFile(datei.path)],
        subject: l10n.sichernBetreff,
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sichernFehler)));
    }
  }

  /// Daten wiederherstellen: Inhalt einer Sicherungsdatei einfügen →
  /// bestätigen → importieren. Der Import validiert und sichert die
  /// Bestandsdaten vorher (siehe LocationRepository.importJson).
  Future<void> _wiederherstellen() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final inhalt = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wiederherstellenTitel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.wiederherstellenText),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 4,
              maxLines: 7,
              autofocus: true,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(hintText: l10n.wiederherstellenHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.abbrechen),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.wiederherstellenAktion),
          ),
        ],
      ),
    );
    controller.dispose();
    if (inhalt == null || inhalt.trim().isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(appDataProvider.notifier).importJson(inhalt);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.wiederherstellenErfolg)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.wiederherstellenFehler)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDaten = ref.watch(appDataProvider);
    final kategorien = ref.watch(kategorienProvider);
    final ausgeblendet = ref.watch(ausgeblendeteIdsProvider);
    final locations = ref
        .watch(locationsProvider)
        .where((location) => !ausgeblendet.contains(location.id))
        .toList();

    if (asyncDaten.hasValue) {
      _planeNaechsteAktualisierung(locations);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _zeigeLadefehlerFallsNoetig(),
      );
    }

    final ansichten = _ansichten(kategorien, locations);
    if (_seite >= ansichten.length) {
      _seite = 0;
    }
    final aktiveAnsicht = ansichten[_seite];

    final offen = locations
        .where((l) => OpenStatusService.isOpenNow(l, _jetzt).offen)
        .length;
    final zeigeUebersicht = asyncDaten.hasValue && locations.isNotEmpty;

    // Kategorie-Farbe je Eintrag für den Akzentstreifen der Liste.
    final katFarbe = {for (final k in kategorien) k.id: farbeAusHex(k.farbe)};
    Color akzentFuer(Location l) =>
        katFarbe[l.kategorie] ?? AppColors.kategorieFallback;

    return Scaffold(
      body: Column(
        children: [
          _HomeHeader(
            l10n: l10n,
            jetzt: _jetzt,
            offen: zeigeUebersicht ? offen : null,
            zu: zeigeUebersicht ? locations.length - offen : null,
            onSuche: () => _suche(locations, l10n),
            onVerwalten: () => context.push('/kategorien'),
            onSichern: _sichern,
            onWiederherstellen: _wiederherstellen,
          ),
          Expanded(
            child: asyncDaten.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (_) => locations.isEmpty
                  ? _Leerzustand(l10n: l10n)
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: ansichten.length,
                      onPageChanged: (seite) => setState(() => _seite = seite),
                      itemBuilder: (context, index) => _AnsichtListe(
                        ansicht: ansichten[index],
                        kategorien: kategorien,
                        locations: locations,
                        jetzt: _jetzt,
                        l10n: l10n,
                        akzentFuer: akzentFuer,
                      ),
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        label: aktiveAnsicht.label(l10n),
        punktFarbe: aktiveAnsicht.punktFarbe(),
        seiten: ansichten.length,
        aktiveSeite: _seite,
        onUmschalter: () => zeigeAnsichtSheet(
          context: context,
          ref: ref,
          alleAktiv: aktiveAnsicht.istAlle,
          aktiveKategorieId: aktiveAnsicht.istSonstige
              ? ''
              : aktiveAnsicht.kategorie?.id,
          onAuswahl: (auswahl) {
            final neueAnsichten = _ansichten(
              ref.read(kategorienProvider),
              ref.read(locationsProvider),
            );
            final ziel = auswahl.istAlle
                ? 0
                : neueAnsichten.indexWhere(
                    (a) => auswahl.kategorieId == ''
                        ? a.istSonstige
                        : a.kategorie?.id == auswahl.kategorieId,
                  );
            if (ziel >= 0) _geheZuSeite(ziel);
          },
          onVerwalten: () => context.push('/kategorien'),
        ),
        onNeu: () => _neuerEintrag(aktiveAnsicht),
      ),
    );
  }
}

/// Hero-Header (v0.3): Markenzeichen + Wortmarke, Datum, „X offen"-Uebersicht.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.l10n,
    required this.jetzt,
    required this.offen,
    required this.zu,
    required this.onSuche,
    required this.onVerwalten,
    required this.onSichern,
    required this.onWiederherstellen,
  });

  final AppLocalizations l10n;
  final DateTime jetzt;
  final int? offen;
  final int? zu;
  final VoidCallback onSuche;
  final VoidCallback onVerwalten;
  final VoidCallback onSichern;
  final VoidCallback onWiederherstellen;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final datum = DateFormat('EEEE, d. MMMM', 'de').format(jetzt);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _Markenzeichen(),
                const SizedBox(width: 11),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'When',
                        style: TextStyle(color: col.ink),
                      ),
                      const TextSpan(
                        text: 'Open',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: l10n.suche,
                  onPressed: onSuche,
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (wert) {
                    switch (wert) {
                      case 0:
                        onVerwalten();
                      case 1:
                        onSichern();
                      case 2:
                        onWiederherstellen();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: _MenueZeile(
                        icon: Icons.category_outlined,
                        text: l10n.kategorienVerwalten,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 1,
                      child: _MenueZeile(
                        icon: Icons.backup_outlined,
                        text: l10n.menueSichern,
                      ),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: _MenueZeile(
                        icon: Icons.restore,
                        text: l10n.menueWiederherstellen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 2),
              child: Text(
                datum,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: col.muted,
                ),
              ),
            ),
            if (offen != null && zu != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    _UebersichtKachel(
                      zahl: offen!,
                      label: l10n.homeOffenZahl,
                      farbe: col.open,
                      hervorgehoben: true,
                    ),
                    const SizedBox(width: 9),
                    _UebersichtKachel(
                      zahl: zu!,
                      label: l10n.homeZuZahl,
                      farbe: col.closed,
                      hervorgehoben: false,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Indigo-Markenzeichen (Pin) als kleine Kachel im Header.
class _Markenzeichen extends StatelessWidget {
  const _Markenzeichen();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDeep],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.location_on, color: Colors.white, size: 21),
    );
  }
}

/// Eintrag im ⋮-Menü: Icon + Text.
class _MenueZeile extends StatelessWidget {
  const _MenueZeile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.col.muted),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }
}

/// Eine Kachel der Status-Uebersicht („4 jetzt offen" / „8 geschlossen").
class _UebersichtKachel extends StatelessWidget {
  const _UebersichtKachel({
    required this.zahl,
    required this.label,
    required this.farbe,
    required this.hervorgehoben,
  });

  final int zahl;
  final String label;
  final Color farbe;
  final bool hervorgehoben;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: hervorgehoben ? farbe.withValues(alpha: 0.14) : col.card,
          border: Border.all(
            color: hervorgehoben ? Colors.transparent : col.line,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: farbe, shape: BoxShape.circle),
            ),
            const SizedBox(width: 9),
            Text(
              '$zahl',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1,
                color: hervorgehoben ? farbe : col.ink,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, height: 1.15, color: col.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnsichtListe extends ConsumerWidget {
  const _AnsichtListe({
    required this.ansicht,
    required this.kategorien,
    required this.locations,
    required this.jetzt,
    required this.l10n,
    required this.akzentFuer,
  });

  final _Ansicht ansicht;
  final List<Kategorie> kategorien;
  final List<Location> locations;
  final DateTime jetzt;
  final AppLocalizations l10n;
  final Color Function(Location) akzentFuer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gefiltert = locations.where(ansicht.enthaelt).toList();

    if (gefiltert.isEmpty) {
      return _Leerzustand(l10n: l10n);
    }

    Widget tile(Location location) => LocationListTile(
      location: location,
      jetzt: jetzt,
      akzent: akzentFuer(location),
      onTap: () => context.push('/detail/${location.id}'),
      onLongPress: () => zeigeKategorieAendernSheet(
        context: context,
        ref: ref,
        location: location,
      ),
    );

    // Einzelne Kategorie → flache Liste (Mockup).
    if (!ansicht.istAlle) {
      return ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        children: [for (final l in gefiltert) tile(l)],
      );
    }

    // "Alle Orte" → nach Kategorie gruppiert, "Sonstige" zuletzt.
    final kinder = <Widget>[];
    void gruppe(String name, Color? farbe, List<Location> orte) {
      if (orte.isEmpty) return;
      kinder.add(_GruppenKopf(name: name, farbe: farbe, anzahl: orte.length));
      kinder.addAll(orte.map(tile));
    }

    if (kategorien.isEmpty) {
      // Keine Kategorien angelegt → schlichte alphabetische Liste.
      kinder.addAll(gefiltert.map(tile));
    } else {
      for (final kategorie in kategorien) {
        gruppe(
          kategorie.name,
          farbeAusHex(kategorie.farbe),
          gefiltert.where((l) => l.kategorie == kategorie.id).toList(),
        );
      }
      gruppe(
        l10n.sonstige,
        AppColors.kategorieFallback,
        gefiltert.where((l) => l.kategorie == null).toList(),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      children: kinder,
    );
  }
}

class _GruppenKopf extends StatelessWidget {
  const _GruppenKopf({
    required this.name,
    required this.farbe,
    required this.anzahl,
  });

  final String name;
  final Color? farbe;
  final int anzahl;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          if (farbe != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: farbe, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            name.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w800,
              color: col.muted,
            ),
          ),
          const Spacer(),
          Text(
            '$anzahl',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: col.muted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _Leerzustand extends StatelessWidget {
  const _Leerzustand({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.add, size: 46, color: col.primaryInk),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.homeLeerTitel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: col.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.homeLeerHinweis,
              textAlign: TextAlign.center,
              style: TextStyle(color: col.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-Umschalter im Google-Tasks-Stil (E10): Auswahl links,
/// Seiten-Punkte mittig, "+" rechts.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.label,
    required this.punktFarbe,
    required this.seiten,
    required this.aktiveSeite,
    required this.onUmschalter,
    required this.onNeu,
  });

  final String label;
  final Color? punktFarbe;
  final int seiten;
  final int aktiveSeite;
  final VoidCallback onUmschalter;
  final VoidCallback onNeu;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    // SafeArea UM die feste Hoehe (siehe P09-Fix 2): der Navi-Inset kommt
    // additiv UNTER die 64px-Leiste, statt sie zusammenzuquetschen.
    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        border: Border(top: BorderSide(color: col.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: onUmschalter,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: col.chip,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (punktFarbe != null) ...[
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: punktFarbe,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: col.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_up,
                          size: 16,
                          color: col.muted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (seiten > 1)
                  Row(
                    children: [
                      for (var i = 0; i < seiten; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == aktiveSeite ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i == aktiveSeite
                                ? AppColors.primary
                                : col.line,
                          ),
                        ),
                    ],
                  ),
                InkWell(
                  onTap: onNeu,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDeep],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Einfache Namenssuche ueber alle Orte (Header-Lupe).
class _OrtSuche extends SearchDelegate<String?> {
  _OrtSuche({
    required this.locations,
    required this.jetzt,
    required String hint,
    required this.keineTreffer,
  }) : super(searchFieldLabel: hint);

  final List<Location> locations;
  final DateTime jetzt;
  final String keineTreffer;

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  Widget _treffer(BuildContext context) {
    final passend = locations
        .where((l) => l.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (passend.isEmpty) {
      return Center(
        child: Text(
          keineTreffer,
          style: TextStyle(color: context.col.muted),
        ),
      );
    }
    return ListView(
      children: [
        for (final location in passend)
          LocationListTile(
            location: location,
            jetzt: jetzt,
            onTap: () => close(context, location.id),
          ),
      ],
    );
  }

  @override
  Widget buildResults(BuildContext context) => _treffer(context);

  @override
  Widget buildSuggestions(BuildContext context) => _treffer(context);
}
