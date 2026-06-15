import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Methodenauswahl beim Anlegen eines Orts (Punkt 1).
///
/// Der **Standardweg ist lokal**: „Ort suchen" (OpenStreetMap) und „Orte in der
/// Nähe" (Umkreis) stehen prominent oben — sie befüllen Adresse und Zeiten
/// automatisch. „Manuell eingeben" ist bewusst die dritte, dezente Option und
/// öffnet erst dann die Tastatur. So ploppt nicht mehr sofort das Keyboard auf.
class StartAuswahlStep extends StatelessWidget {
  const StartAuswahlStep({
    super.key,
    required this.onSuchen,
    required this.onUmkreis,
    required this.onManuell,
  });

  final VoidCallback onSuchen;
  final VoidCallback onUmkreis;
  final VoidCallback onManuell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final col = context.col;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Text(
          l10n.qeStartFrage,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.qeStartHinweis,
          style: TextStyle(color: col.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 20),
        // „Orte in der Nähe" steht bewusst an erster Stelle: bequemster Weg
        // (Adresse + Zeiten kommen automatisch, knüpft an die Heimatadresse an).
        _MethodeKachel(
          icon: Icons.near_me_outlined,
          titel: l10n.umkreisSuchen,
          info: l10n.qeStartUmkreisInfo,
          hervorgehoben: true,
          onTap: onUmkreis,
        ),
        const SizedBox(height: 12),
        _MethodeKachel(
          icon: Icons.travel_explore,
          titel: l10n.osmSuchTitel,
          info: l10n.qeStartSuchenInfo,
          hervorgehoben: true,
          onTap: onSuchen,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: Divider(color: col.line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.qeStartOder,
                style: TextStyle(
                  color: col.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: col.line)),
          ],
        ),
        const SizedBox(height: 14),
        _MethodeKachel(
          icon: Icons.edit_outlined,
          titel: l10n.qeManuell,
          info: l10n.qeManuellInfo,
          hervorgehoben: false,
          onTap: onManuell,
        ),
      ],
    );
  }
}

/// Eine antippbare Methoden-Kachel: Icon in getöntem Kreis, Titel, Unterzeile.
/// [hervorgehoben] für die lokalen Standardwege (Indigo-Tönung statt grau).
class _MethodeKachel extends StatelessWidget {
  const _MethodeKachel({
    required this.icon,
    required this.titel,
    required this.info,
    required this.hervorgehoben,
    required this.onTap,
  });

  final IconData icon;
  final String titel;
  final String info;
  final bool hervorgehoben;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final akzent = hervorgehoben ? AppColors.primary : col.muted;
    return Material(
      color: hervorgehoben
          ? AppColors.primary.withValues(alpha: 0.10)
          : col.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hervorgehoben
                  ? AppColors.primary.withValues(alpha: 0.30)
                  : col.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: akzent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: hervorgehoben ? col.primaryInk : col.muted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titel,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: col.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      info,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: col.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: col.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
