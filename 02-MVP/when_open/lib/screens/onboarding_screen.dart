import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/app_einstellungen.dart';
import '../providers/locations_provider.dart';
import '../services/url_service.dart';
import '../theme/app_theme.dart';
import '../widgets/heimat_adresse_eingabe.dart';
import 'ueber_screen.dart' show kKontaktEmail, kSpendenUrl;

/// Erstnutzer-Tutorial (Hybrid): erklaerende Themen-Karten (Kategorien, Daten,
/// Adresse, E-Mail, optional Spenden) mit Abschluss-CTA, der direkt in den
/// gefuehrten ersten Eintrag fuehrt. Wird aus dem HomeScreen geoeffnet, wenn
/// die App leer ist und der Tutorial-Status noch [TutorialStatus.offen] ist.
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

  Future<void> _email() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final erfolg = await UrlService.openEmail(
      kKontaktEmail,
      betreff: l10n.ueberKontaktBetreff,
    );
    if (!erfolg) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.ueberLinkFehler)));
    }
  }

  Future<void> _spende() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    var erfolg = false;
    try {
      erfolg = await launchUrl(
        Uri.parse(kSpendenUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      erfolg = false;
    }
    if (!erfolg) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.ueberLinkFehler)));
    }
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
        icon: Icons.mail_outline,
        titel: l10n.onboardingEmailTitel,
        text: l10n.onboardingEmailText,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _email,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryInk,
              backgroundColor: AppColors.chip,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.mail_outline, size: 18),
            label: Text(l10n.onboardingEmailButton),
          ),
        ),
      ),
      if (kSpendenUrl.isNotEmpty)
        _Seite(
          icon: Icons.favorite_rounded,
          titel: l10n.onboardingSpendenTitel,
          text: l10n.onboardingSpendenText,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _spende,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryInk,
                backgroundColor: AppColors.chip,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.favorite_rounded, size: 18),
              label: Text(l10n.ueberKaffeeButton),
            ),
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
