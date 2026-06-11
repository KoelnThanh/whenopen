import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/location.dart';
import '../services/open_status_service.dart';
import '../theme/app_theme.dart';

/// Eine Zeile der Hauptliste (v0.3): schlanke Karte mit Kategorie-Akzentstreifen
/// links, Name und farbiger Uhrzeit (grün offen / grau zu) rechts — kein Kasten,
/// kein Punkt.
class LocationListTile extends StatelessWidget {
  const LocationListTile({
    super.key,
    required this.location,
    required this.jetzt,
    required this.onTap,
    this.onLongPress,
    this.akzent,
  });

  final Location location;
  final DateTime jetzt;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Farbe des Akzentstreifens (Kategorie). Null → Markenfarbe.
  final Color? akzent;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final l10n = AppLocalizations.of(context)!;
    final status = OpenStatusService.isOpenNow(location, jetzt);
    final statusText = OpenStatusService.statusText(status, l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: col.card,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: col.line),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 7,
                  top: 11,
                  bottom: 11,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: akzent ?? AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(19, 13, 12, 13),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          location.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                status.offen ? FontWeight.w600 : FontWeight.w500,
                            color: status.offen ? col.ink : col.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: status.offen ? col.open : col.muted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: col.muted.withValues(alpha: 0.5),
                      ),
                    ],
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
