import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/opening_day.dart';
import '../../theme/app_theme.dart';

/// Schritte 2–8/10: ein Wochentag mit Mehrblock-Editor (E9).
/// Drei Optionen: Geoeffnet · Gleiche Zeiten (Vorschlag) · Geschlossen.
class DayEntryStep extends StatelessWidget {
  const DayEntryStep({
    super.key,
    required this.tagName,
    required this.bloecke,
    required this.vorschlag,
    required this.onChanged,
  });

  final String tagName;
  final List<TimeBlock> bloecke;

  /// Bloecke des letzten geoeffneten Tags (null = noch keiner eingetragen).
  final List<TimeBlock>? vorschlag;

  final ValueChanged<List<TimeBlock>> onChanged;

  static const _defaultBlock = TimeBlock(
    von: TimeOfDay(hour: 9, minute: 0),
    bis: TimeOfDay(hour: 18, minute: 0),
  );

  bool get _geoeffnet => bloecke.isNotEmpty;

  void _waehleGeoeffnet() {
    if (_geoeffnet) return;
    final v = vorschlag;
    onChanged(v != null ? [...v] : [_defaultBlock]);
  }

  void _waehleGleicheZeiten() {
    if (vorschlag == null) return;
    onChanged([...vorschlag!]);
  }

  void _waehleGeschlossen() => onChanged(const []);

  /// Neuer Block: beginnt 2h nach dem Ende des letzten, dauert 3h (geclampt).
  void _blockHinzufuegen() {
    if (bloecke.isEmpty) {
      onChanged([_defaultBlock]);
      return;
    }
    final letztesEnde = bloecke.last.bis.inMinuten;
    final von = (letztesEnde + 120).clamp(0, 22 * 60);
    final bis = (von + 180).clamp(0, 23 * 60 + 30);
    onChanged([
      ...bloecke,
      TimeBlock(
        von: TimeOfDay(hour: von ~/ 60, minute: von % 60),
        bis: TimeOfDay(hour: bis ~/ 60, minute: bis % 60),
      ),
    ]);
  }

  Future<void> _zeitWaehlen(
      BuildContext context, int index, bool istVon) async {
    final block = bloecke[index];
    final gewaehlt = await showTimePicker(
      context: context,
      initialTime: istVon ? block.von : block.bis,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (gewaehlt == null) return;
    final neue = [...bloecke];
    neue[index] =
        istVon ? block.copyWith(von: gewaehlt) : block.copyWith(bis: gewaehlt);
    onChanged(neue);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tagName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(l10n.qeTagHint,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              _ChoiceChip(
                label: l10n.qeGeoeffnet,
                selected: _geoeffnet,
                onTap: _waehleGeoeffnet,
              ),
              const SizedBox(width: 8),
              _ChoiceChip(
                label: l10n.qeGleicheZeiten,
                selected: false,
                enabled: vorschlag != null,
                onTap: _waehleGleicheZeiten,
              ),
              const SizedBox(width: 8),
              _ChoiceChip(
                label: l10n.qeGeschlossen,
                selected: !_geoeffnet,
                onTap: _waehleGeschlossen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_geoeffnet) ...[
            for (var i = 0; i < bloecke.length; i++) ...[
              _BlockRow(
                block: bloecke[i],
                oeffnetLabel: l10n.qeOeffnet,
                schliesstLabel: l10n.qeSchliesst,
                entfernenTooltip: l10n.qeBlockEntfernen,
                onVonTap: () => _zeitWaehlen(context, i, true),
                onBisTap: () => _zeitWaehlen(context, i, false),
                onEntfernen: () =>
                    onChanged([...bloecke]..removeAt(i)),
              ),
              const SizedBox(height: 10),
            ],
            TextButton(
              onPressed: _blockHinzufuegen,
              child: Text(l10n.qeWeitererBlock,
                  style: const TextStyle(color: AppColors.primaryInk)),
            ),
            Text(l10n.qeBlockHint,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.card,
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (enabled ? AppColors.muted : AppColors.muted.withValues(alpha: 0.4)),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({
    required this.block,
    required this.oeffnetLabel,
    required this.schliesstLabel,
    required this.entfernenTooltip,
    required this.onVonTap,
    required this.onBisTap,
    required this.onEntfernen,
  });

  final TimeBlock block;
  final String oeffnetLabel;
  final String schliesstLabel;
  final String entfernenTooltip;
  final VoidCallback onVonTap;
  final VoidCallback onBisTap;
  final VoidCallback onEntfernen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _ZeitZelle(
                label: oeffnetLabel, zeit: block.von, onTap: onVonTap)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('–', style: TextStyle(color: AppColors.muted)),
        ),
        Expanded(
            child: _ZeitZelle(
                label: schliesstLabel, zeit: block.bis, onTap: onBisTap)),
        IconButton(
          onPressed: onEntfernen,
          tooltip: entfernenTooltip,
          icon: const Icon(Icons.close, color: AppColors.danger, size: 18),
        ),
      ],
    );
  }
}

class _ZeitZelle extends StatelessWidget {
  const _ZeitZelle(
      {required this.label, required this.zeit, required this.onTap});

  final String label;
  final TimeOfDay zeit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.muted)),
            Text(zeit.alsString, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
