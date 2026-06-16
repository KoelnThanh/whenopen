import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Eine Frage-Antwort-Einheit. Bewusst **inline** statt über l10n geführt,
/// damit die Texte ohne ARB-Escaping frei angepasst werden können (wie die
/// „Über mich"-Prosa).
typedef FaqEintrag = ({String frage, String antwort});

/// Inhaltliche Transparenz-FAQ. Beantwortet die typischen „Wo ist der Haken?"-
/// Fragen einer lokalen, trackingfreien App ehrlich — Reihenfolge = Relevanz.
const List<FaqEintrag> kFaqEintraege = [
  (
    frage: 'Wo werden meine Daten gespeichert?',
    antwort: 'Ausschließlich auf deinem Gerät. WhenOpen hat kein Konto, keine '
        'Cloud und kein Tracking. Deine Orte und Öffnungszeiten liegen in einer '
        'einzigen Datei in der App — niemand außer dir sieht sie, und es wird '
        'nichts an einen Server gesendet.',
  ),
  (
    frage: 'Brauche ich eine Internetverbindung?',
    antwort: 'Für den normalen Gebrauch nicht. Die Liste, das Widget und alle '
        'gespeicherten Zeiten funktionieren komplett offline. Internet braucht '
        'nur die optionale Suche: „Ort suchen" und „Orte in der Nähe" fragen '
        'OpenStreetMap ab, um dir Adressen und Zeiten vorzuschlagen.',
  ),
  (
    frage: 'Warum fragt die App nicht nach meinem Standort?',
    antwort: 'Weil sie keine Standortfreigabe braucht. Statt GPS hinterlegst du '
        'einmal deine Heimatadresse — sie wird einmalig in Koordinaten '
        'umgewandelt und bleibt lokal gespeichert. So findet „Orte in der Nähe" '
        'deine Umgebung, ohne dass die App dich laufend orten muss.',
  ),
  (
    frage: 'Was passiert bei einem Handy-Wechsel?',
    antwort: 'Über das ⋮-Menü kannst du deine Daten „Sichern" (eine Datei im '
        'Ordner Download/WhenOpen) oder „Teilen" (z. B. an dich selbst per '
        'Mail/Cloud). Auf dem neuen Gerät wählst du „Wiederherstellen" und lädst '
        'die Datei wieder ein. Die Sicherung ist eine offene Klartext-Datei — '
        'bewahre sie so vertraulich auf, wie du es möchtest.',
  ),
  (
    frage: 'Warum ist WhenOpen kostenlos?',
    antwort: 'Weil es als persönliches Projekt entstanden ist und kein '
        'Geschäftsmodell dahintersteht — keine Werbung, keine Daten, keine '
        'In-App-Käufe. Wenn dir die App den Alltag erleichtert, freue ich mich '
        'über eine freiwillige Spende; sie schaltet aber nichts frei.',
  ),
  (
    frage: 'Warum kann ich keine Zeiten über Mitternacht eintragen?',
    antwort: 'WhenOpen rechnet bewusst Tag für Tag, damit „jetzt offen?" '
        'eindeutig bleibt. Eine Bar bis 02:00 oder echtes 24/7 sprengt dieses '
        'einfache Modell — das ist eine bewusste Grenze, keine fehlende '
        'Funktion. Als Behelf kannst du den letzten Block bis 23:59 setzen.',
  ),
  (
    frage: 'Woher kommen die übernommenen Öffnungszeiten?',
    antwort: 'Aus OpenStreetMap, einer offenen Karten-Datenbank. Die Daten sind '
        'meist gut, können aber veralten oder lückenhaft sein. Prüfe sie im '
        'Schritt „Daten prüfen" und passe alles an — am Ende zählt, was du '
        'selbst einträgst.',
  ),
];

/// „Fragen & Antworten": Transparenz-FAQ als ausklappbare Liste.
/// Erreichbar über das ⋮-Menü im Home-Header (Route `/faq`).
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final col = context.col;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.faqTitel)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text(
              l10n.faqUntertitel,
              style: TextStyle(fontSize: 13, height: 1.45, color: col.muted),
            ),
            const SizedBox(height: 16),
            for (final eintrag in kFaqEintraege) ...[
              _FaqKarte(eintrag: eintrag),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// Eine ausklappbare FAQ-Karte (Frage als Kopf, Antwort beim Aufklappen).
class _FaqKarte extends StatelessWidget {
  const _FaqKarte({required this.eintrag});

  final FaqEintrag eintrag;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: col.line),
      ),
      child: Theme(
        // Trennlinie der ExpansionTile ausblenden — die Karte rahmt schon.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: AppColors.primary,
          collapsedIconColor: col.muted,
          title: Text(
            eintrag.frage,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: col.ink,
            ),
          ),
          children: [
            Text(
              eintrag.antwort,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: col.ink),
            ),
          ],
        ),
      ),
    );
  }
}
