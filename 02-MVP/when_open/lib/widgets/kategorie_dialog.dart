import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Ergebnis des "Neue Kategorie"-Dialogs.
class NeueKategorieErgebnis {
  const NeueKategorieErgebnis({required this.name, this.farbe});

  final String name;

  /// Hex-String (z.B. "#5b8def") oder null.
  final String? farbe;
}

/// Dialog "Neue Kategorie" (E15): Name + Farb-Swatches.
/// Wird im Schnelleintrag, im Auswahl-Sheet und in der Verwaltung genutzt.
Future<NeueKategorieErgebnis?> zeigeNeueKategorieDialog(
  BuildContext context, {
  String? initialName,
  String? initialFarbe,
  String? titel,
}) {
  return showDialog<NeueKategorieErgebnis>(
    context: context,
    builder: (context) => _KategorieDialog(
      initialName: initialName,
      initialFarbe: initialFarbe,
      titel: titel,
    ),
  );
}

String _farbeZuHex(Color farbe) {
  final argb = farbe.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// Hex-String ("#rrggbb") → Color; null/ungueltig → Fallback-Grau.
Color farbeAusHex(String? hex) {
  if (hex == null) return AppColors.kategorieFallback;
  final wert = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (wert == null) return AppColors.kategorieFallback;
  return Color(0xFF000000 | wert);
}

class _KategorieDialog extends StatefulWidget {
  const _KategorieDialog({this.initialName, this.initialFarbe, this.titel});

  final String? initialName;
  final String? initialFarbe;
  final String? titel;

  @override
  State<_KategorieDialog> createState() => _KategorieDialogState();
}

class _KategorieDialogState extends State<_KategorieDialog> {
  late final TextEditingController _nameController;
  String? _farbe;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _farbe = widget.initialFarbe;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.titel ?? l10n.katNeuTitel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.katNeuHint,
              style: TextStyle(color: col.muted, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l10n.katName),
          ),
          const SizedBox(height: 14),
          Text(l10n.katFarbe,
              style: TextStyle(color: col.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final farbe in AppColors.kategorieFarben) ...[
                GestureDetector(
                  onTap: () => setState(() => _farbe = _farbeZuHex(farbe)),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: farbe,
                      shape: BoxShape.circle,
                      border: _farbe == _farbeZuHex(farbe)
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.qeAbbrechen),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context)
                .pop(NeueKategorieErgebnis(name: name, farbe: _farbe));
          },
          child: Text(l10n.katAnlegen),
        ),
      ],
    );
  }
}
