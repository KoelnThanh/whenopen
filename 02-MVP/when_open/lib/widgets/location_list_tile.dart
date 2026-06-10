import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/location.dart';
import '../services/open_status_service.dart';
import '../theme/app_theme.dart';

/// Eine Zeile der Hauptliste: Status-Punkt, Name, Statustext, Chevron.
class LocationListTile extends StatelessWidget {
  const LocationListTile({
    super.key,
    required this.location,
    required this.jetzt,
    required this.onTap,
    this.onLongPress,
  });

  final Location location;
  final DateTime jetzt;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = OpenStatusService.isOpenNow(location, jetzt);
    final statusText = OpenStatusService.statusText(status, l10n);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status.offen ? AppColors.open : AppColors.closed,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                location.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      status.offen ? FontWeight.w500 : FontWeight.w400,
                  color: status.offen ? AppColors.ink : AppColors.muted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: status.offen ? AppColors.open : AppColors.muted,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 18, color: Color(0xFF555C66)),
          ],
        ),
      ),
    );
  }
}
