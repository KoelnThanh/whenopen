import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.suche,
            onPressed: () async {
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
            },
          ),
        ],
      ),
      body: asyncDaten.when(
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
                ),
              ),
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

class _AnsichtListe extends ConsumerWidget {
  const _AnsichtListe({
    required this.ansicht,
    required this.kategorien,
    required this.locations,
    required this.jetzt,
    required this.l10n,
  });

  final _Ansicht ansicht;
  final List<Kategorie> kategorien;
  final List<Location> locations;
  final DateTime jetzt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gefiltert = locations.where(ansicht.enthaelt).toList();

    if (gefiltert.isEmpty) {
      return _Leerzustand(l10n: l10n);
    }

    Widget tile(Location location) => LocationListTile(
      location: location,
      jetzt: jetzt,
      onTap: () => context.push('/detail/${location.id}'),
      onLongPress: () => zeigeKategorieAendernSheet(
        context: context,
        ref: ref,
        location: location,
      ),
    );

    // Einzelne Kategorie → flache Liste (Mockup).
    if (!ansicht.istAlle) {
      return ListView(children: [for (final l in gefiltert) tile(l)]);
    }

    // "Alle Orte" → nach Kategorie gruppiert, "Sonstige" zuletzt.
    final kinder = <Widget>[];
    void gruppe(String name, List<Location> orte) {
      if (orte.isEmpty) return;
      kinder.add(_GruppenKopf(name: name, anzahl: orte.length));
      kinder.addAll(orte.map(tile));
    }

    if (kategorien.isEmpty) {
      // Keine Kategorien angelegt → schlichte alphabetische Liste.
      kinder.addAll(gefiltert.map(tile));
    } else {
      for (final kategorie in kategorien) {
        gruppe(
          kategorie.name,
          gefiltert.where((l) => l.kategorie == kategorie.id).toList(),
        );
      }
      gruppe(
        l10n.sonstige,
        gefiltert.where((l) => l.kategorie == null).toList(),
      );
    }

    return ListView(children: kinder);
  }
}

class _GruppenKopf extends StatelessWidget {
  const _GruppenKopf({required this.name, required this.anzahl});

  final String name;
  final int anzahl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          Text(
            '$anzahl',
            style: const TextStyle(fontSize: 11, color: Color(0xFF5B626D)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 72,
              color: Color(0xFF3A414C),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.homeLeerTitel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.homeLeerHinweis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
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
    // SafeArea UM die feste Hoehe: der Abstand fuer die System-
    // Navigationsleiste kommt additiv UNTER die 64px-Leiste, statt sie von
    // innen aufzufressen. Sonst wird die Leiste auf 3-Tasten-Navigation
    // (grosser unterer Inset) zusammengequetscht. Die Hintergrundfarbe liegt
    // am aeusseren Container, damit sie auch den Inset-Streifen fuellt.
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141821),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onUmschalter,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (punktFarbe != null) ...[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: punktFarbe,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_up,
                        size: 16,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
              if (seiten > 1)
                Row(
                  children: [
                    for (var i = 0; i < seiten; i++)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == aktiveSeite
                              ? AppColors.primaryInk
                              : const Color(0xFF3A414C),
                        ),
                      ),
                  ],
                ),
              InkWell(
                onTap: onNeu,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Einfache Namenssuche ueber alle Orte (AppBar-Lupe).
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
          style: const TextStyle(color: AppColors.muted),
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
