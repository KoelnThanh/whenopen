import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../models/app_einstellungen.dart';
import '../providers/locations_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/heimat_adresse_eingabe.dart';

/// Erstnutzer-Tutorial (Hybrid): erklaerende Themen-Karten (Widget, Kategorien,
/// Daten, Adresse) mit Abschluss-CTA, der direkt in den gefuehrten ersten
/// Eintrag fuehrt. Wird aus dem HomeScreen geoeffnet, wenn die App leer ist und
/// der Tutorial-Status noch [TutorialStatus.offen] ist. E-Mail/Spende kommen
/// bewusst NICHT hier vor, sondern erst ab dem 5. gespeicherten Ort (Punkt 3,
/// siehe HomeScreen._zeigeSpendenhinweisFallsNoetig).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _seite = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Tutorial beenden: Status persistieren und entweder in den gefuehrten
  /// ersten Eintrag wechseln oder zum HomeScreen zurueck.
  Future<void> _beenden({required bool starteEintrag}) async {
    await ref
        .read(appDataProvider.notifier)
        .setTutorialStatus(TutorialStatus.abgeschlossen);
    if (!mounted) return;
    if (starteEintrag) {
      context.pushReplacement('/quick-entry?tutorial=1');
    } else {
      context.pop();
    }
  }

  void _weiter(int anzahl) {
    if (_seite >= anzahl - 1) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final einst = ref.watch(einstellungenProvider);
    final col = context.col;

    final seiten = <Widget>[
      _Seite(
        icon: Icons.location_on,
        titel: l10n.onboardingWillkommenTitel,
        text: l10n.onboardingWillkommenText,
      ),
      // Kerngeschichte: Die App entfaltet ihren Nutzen erst als Widget auf dem
      // Startbildschirm — deshalb früh und mit Schritt-für-Schritt-Anleitung.
      _Seite(
        icon: Icons.widgets_outlined,
        titel: l10n.onboardingWidgetTitel,
        text: l10n.onboardingWidgetText,
        child: const _WidgetSchritte(),
      ),
      _Seite(
        icon: Icons.category_outlined,
        titel: l10n.onboardingKategorienTitel,
        text: l10n.onboardingKategorienText,
      ),
      _Seite(
        icon: Icons.travel_explore,
        titel: l10n.onboardingDatenTitel,
        text: l10n.onboardingDatenText,
      ),
      _Seite(
        icon: Icons.home_outlined,
        titel: l10n.onboardingAdresseTitel,
        text: l10n.onboardingAdresseText,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeimatAdresseEingabe(
              adresse: einst.heimatAdresse,
              hatHeimat: einst.hatHeimat,
              onGewaehlt: (adresse, lat, lon) =>
                  ref.read(appDataProvider.notifier).setEinstellungen(
                        einst.copyWith(
                          heimatAdresse: adresse,
                          heimatLat: lat,
                          heimatLon: lon,
                        ),
                      ),
              onEntfernen: () => ref
                  .read(appDataProvider.notifier)
                  .setEinstellungen(einst.copyWith(heimatLoeschen: true)),
            ),
            if (einst.hatHeimat) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: col.open),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.onboardingAdresseGesetzt,
                      style: TextStyle(fontSize: 13, color: col.open),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      _Seite(
        icon: Icons.rocket_launch_outlined,
        titel: l10n.onboardingFertigTitel,
        text: l10n.onboardingFertigText,
      ),
    ];

    if (_seite >= seiten.length) _seite = seiten.length - 1;
    final istLetzte = _seite == seiten.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Kopf: „Überspringen“ rechts.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                child: TextButton(
                  onPressed: () => _beenden(starteEintrag: false),
                  child: Text(l10n.onboardingUeberspringen),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _seite = i),
                children: seiten,
              ),
            ),
            // Seiten-Punkte.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < seiten.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _seite ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _seite ? AppColors.primary : col.line,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: istLetzte
                      ? () => _beenden(starteEintrag: true)
                      : () => _weiter(seiten.length),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(istLetzte
                      ? l10n.onboardingErsterOrt
                      : l10n.onboardingWeiter),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Einzelne Tutorial-Karte: Icon im getoenten Kreis, Titel, Fliesstext und
/// optional ein interaktiver Inhalt (z. B. die Adress-Eingabe).
class _Seite extends StatelessWidget {
  const _Seite({
    required this.icon,
    required this.titel,
    required this.text,
    this.child,
  });

  final IconData icon;
  final String titel;
  final String text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 40, color: col.primaryInk),
          ),
          const SizedBox(height: 26),
          Text(
            titel,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: col.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(fontSize: 15, height: 1.5, color: col.muted),
          ),
          if (child != null) ...[
            const SizedBox(height: 24),
            child!,
          ],
        ],
      ),
    );
  }
}

/// Schritt-für-Schritt-Anleitung „Widget hinzufügen" auf der Widget-Tutorial-
/// Seite — nummerierte Zeilen, damit der wichtigste Handgriff klar ist.
class _WidgetSchritte extends StatelessWidget {
  const _WidgetSchritte();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final col = context.col;
    final schritte = [
      l10n.onboardingWidgetSchritt1,
      l10n.onboardingWidgetSchritt2,
      l10n.onboardingWidgetSchritt3,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < schritte.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      schritte[i],
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: col.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
