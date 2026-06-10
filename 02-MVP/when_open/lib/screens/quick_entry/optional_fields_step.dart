import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Schritt 10/10: optionale Felder (Adresse, Telefon, Google Maps Link).
class OptionalFieldsStep extends StatelessWidget {
  const OptionalFieldsStep({
    super.key,
    required this.adresseController,
    required this.telefonController,
    required this.mapsLinkController,
    required this.zeigeUrlFehler,
  });

  final TextEditingController adresseController;
  final TextEditingController telefonController;
  final TextEditingController mapsLinkController;
  final bool zeigeUrlFehler;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.qeZusatzTitel,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(l10n.qeZusatzHint,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: adresseController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.qeAdresse),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: telefonController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.qeTelefon),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: mapsLinkController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.qeMapsLink,
              errorText: zeigeUrlFehler ? l10n.valUngueltigeUrl : null,
            ),
          ),
        ],
      ),
    );
  }
}
