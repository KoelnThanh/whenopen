import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/url_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

// ─────────────────────────────────────────────────────────────────────────
//  SPENDENLINK — hier eintragen (von Thanh).
//  Beispiel PayPal.me:  'https://paypal.me/deinname'
//  Beispiel Ko-fi:      'https://ko-fi.com/deinname'
//  Solange dieser String leer ('') ist, blendet sich der Unterstützen-Button
//  automatisch aus — es wird also nie ein toter Link veröffentlicht.
const String kSpendenUrl = 'https://paypal.me/koelnthanh';
// ─────────────────────────────────────────────────────────────────────────

/// Kontakt-/Feedback-Adresse. Leerer String blendet den Kontakt-Block aus.
const String kKontaktEmail = 'koeln.thanh@gmail.com';

/// App-Version — synchron zu `pubspec.yaml` halten (kein package_info nötig).
const String kAppVersion = '1.0.0';

/// Persönlicher „Über mich"-Text. Frei editierbar — das ist Thanhs eigene
/// Stimme, bewusst nicht über l10n geführt, damit die Prosa ohne ARB-
/// Escaping angepasst werden kann.
const String kUeberGruss = 'Hi, ich bin Thanh 👋';
const List<String> kUeberAbsaetze = [
  'In meiner Freizeit fasziniert mich, was mit KI heute alles möglich ist — '
      'und ich probiere gerne Dinge aus, die den Alltag leichter machen. Als '
      'Familienvater zählt für mich jede kleine Optimierung.',
  'WhenOpen ist aus genau so einem Bedürfnis entstanden: Ich wollte auf einen '
      'Blick sehen, was bei meinen lokalen Orten gerade offen hat — ohne mich '
      'immer wieder durch Google Maps zu klicken. Die App speichert alles nur '
      'auf deinem Gerät: kein Konto, keine Cloud, kein Tracking. Das war mir '
      'wichtig.',
  'Wenn dir WhenOpen den Alltag ein bisschen leichter macht, freue ich mich '
      'riesig. Und falls du magst, spendier mir einen Kaffee ☕ — das hält die '
      'Motivation für die nächsten Ideen hoch.',
  'Danke, dass du dabei bist! — Thanh',
];

/// „Über WhenOpen": persönliche Vorstellung + freiwilliger Unterstützen-Bereich.
/// Erreichbar über das ⋮-Menü im Home-Header (Route `/ueber`).
class UeberScreen extends StatelessWidget {
  const UeberScreen({super.key});

  Future<void> _spende(BuildContext context) async {
    if (kSpendenUrl.isEmpty) return;
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

  Future<void> _kontakt(BuildContext context) async {
    if (kKontaktEmail.isEmpty) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final col = context.col;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ueberTitel)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            // Markenkopf — Pin + Wortmarke + Tagline, zentriert.
            const SizedBox(height: 8),
            const Center(child: WhenOpenLogo(size: 64)),
            const SizedBox(height: 14),
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'When', style: TextStyle(color: col.ink)),
                    const TextSpan(
                      text: 'Open',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                l10n.ueberTagline,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: col.muted),
              ),
            ),
            const SizedBox(height: 28),

            // Über-mich-Karte.
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: col.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: col.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kUeberGruss,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: col.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < kUeberAbsaetze.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    Text(
                      kUeberAbsaetze[i],
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: col.ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Kontakt-/Feedback-Bereich — nur wenn eine Adresse hinterlegt ist.
            if (kKontaktEmail.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                l10n.ueberKontaktTitel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.ueberKontaktHinweis,
                style: TextStyle(fontSize: 13, height: 1.45, color: col.muted),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _kontakt(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryInk,
                    backgroundColor: AppColors.chip,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: Text(l10n.ueberKontaktButton),
                ),
              ),
            ],

            // Unterstützen-Bereich — nur wenn ein Spendenlink hinterlegt ist.
            if (kSpendenUrl.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                l10n.ueberUnterstuetzenTitel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.ueberUnterstuetzenHinweis,
                style: TextStyle(fontSize: 13, height: 1.45, color: col.muted),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _spende(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.favorite_rounded, size: 18),
                  label: Text(l10n.ueberKaffeeButton),
                ),
              ),
            ],

            const SizedBox(height: 28),
            Center(
              child: Text(
                l10n.ueberVersion(kAppVersion),
                style: TextStyle(fontSize: 12, color: col.muted),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                l10n.einstAttribution,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: col.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
