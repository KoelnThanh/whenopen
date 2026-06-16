import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/opening_day.dart';
import '../../models/wochentag.dart';
import '../../services/open_status_service.dart';
import '../../theme/app_theme.dart';
import 'quick_entry_state.dart';

/// Schritt 2/4: Öffnungszeiten als EINE Wochenliste mit Akkordeon-Editor
/// („Eine Woche, ein Editor", UX-Redesign 2026-06).
///
/// Pro Tag drei Zustände: geöffnet (Blöcke), geschlossen (festgelegt & leer),
/// „noch festlegen" (noch nicht in [QuickEntryState.festgelegt]). Immer höchstens
/// ein Tag aufgeklappt. „Weiter" im Editor springt zum nächsten noch nicht
/// festgelegten Tag — bei Neuanlage führt das durch die Woche, bei Import/
/// Bearbeiten (alles schon festgelegt) klappt es einfach zu.
class WeekHoursStep extends StatefulWidget {
  const WeekHoursStep({
    super.key,
    required this.state,
    required this.onChanged,
  });

  final QuickEntryState state;

  /// Wird nach jeder Datenänderung gerufen (Screen aktualisiert Fortschritt).
  final VoidCallback onChanged;

  @override
  State<WeekHoursStep> createState() => _WeekHoursStepState();
}

class _WeekHoursStepState extends State<WeekHoursStep> {
  /// Aktuell aufgeklappter Tag (null = keiner).
  Wochentag? _aktiv;

  static const _defaultBlock = TimeBlock(
    von: TimeOfDay(hour: 9, minute: 0),
    bis: TimeOfDay(hour: 18, minute: 0),
  );

  QuickEntryState get _state => widget.state;

  @override
  void initState() {
    super.initState();
    // Neuanlage (nichts festgelegt) startet bei Montag (neutral), damit die
    // Woche sich von oben aufbaut. Import/Bearbeiten startet zugeklappt.
    _aktiv = _state.festgelegt.isEmpty ? Wochentag.montag : null;
  }

  void _melde() => widget.onChanged();

  bool _istOffen(Wochentag tag) => _state.zeiten[tag]!.isNotEmpty;
  bool _istFestgelegt(Wochentag tag) => _state.festgelegt.contains(tag);

  void _oeffneTag(Wochentag tag) => setState(() => _aktiv = tag);

  void _weiter(Wochentag tag) =>
      setState(() => _aktiv = _state.naechsterUnbestimmter(tag));

  void _waehleGeoeffnet(Wochentag tag) {
    setState(() {
      _state.festgelegt.add(tag);
      if (_state.zeiten[tag]!.isEmpty) {
        _state.zeiten[tag] = [_defaultBlock];
      }
    });
    _melde();
  }

  void _waehleGeschlossen(Wochentag tag) {
    setState(() {
      _state.festgelegt.add(tag);
      _state.zeiten[tag] = [];
    });
    _melde();
    _weiter(tag); // geschlossen ist eine vollständige Entscheidung → weiter
  }

  /// Übernimmt die Blöcke eines anderen Tags (einmalige Kopie, keine Bindung).
  void _uebernimm(Wochentag tag, List<TimeBlock> bloecke) {
    setState(() {
      _state.festgelegt.add(tag);
      _state.zeiten[tag] = [...bloecke];
    });
    _melde();
  }

  void _blockHinzufuegen(Wochentag tag) {
    final bloecke = _state.zeiten[tag]!;
    if (bloecke.isEmpty) {
      setState(() => _state.zeiten[tag] = [_defaultBlock]);
      _melde();
      return;
    }
    // Neuer Block: 2 h nach dem letzten Ende, 3 h Dauer — bis 23:59 (P-UX:
    // „fast Mitternacht" möglich; echte Über-Nacht-Zeiten bleiben v2).
    final letztesEnde = bloecke.last.bis.inMinuten;
    final von = (letztesEnde + 120).clamp(0, 23 * 60);
    final bis = (von + 180).clamp(0, 23 * 60 + 59);
    setState(() {
      _state.zeiten[tag] = [
        ...bloecke,
        TimeBlock(
          von: TimeOfDay(hour: von ~/ 60, minute: von % 60),
          bis: TimeOfDay(hour: bis ~/ 60, minute: bis % 60),
        ),
      ];
    });
    _melde();
  }

  void _blockEntfernen(Wochentag tag, int index) {
    setState(() => _state.zeiten[tag] = [..._state.zeiten[tag]!]..removeAt(index));
    _melde();
  }

  Future<void> _zeitWaehlen(Wochentag tag, int index, bool istVon) async {
    final block = _state.zeiten[tag]![index];
    final gewaehlt = await showTimePicker(
      context: context,
      initialTime: istVon ? block.von : block.bis,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (gewaehlt == null) return;
    final neue = [..._state.zeiten[tag]!];
    neue[index] =
        istVon ? block.copyWith(von: gewaehlt) : block.copyWith(bis: gewaehlt);
    setState(() => _state.zeiten[tag] = neue);
    _melde();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.qeWocheTitel,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          for (final tag in Wochentag.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _aktiv == tag
                  ? _TagEditor(
                      tag: tag,
                      l10n: l10n,
                      offen: _istOffen(tag),
                      festgelegt: _istFestgelegt(tag),
                      bloecke: _state.zeiten[tag]!,
                      vorschlaege: _state.uebernahmeVorschlaege(tag),
                      naechster: _state.naechsterUnbestimmter(tag),
                      onGeoeffnet: () => _waehleGeoeffnet(tag),
                      onGeschlossen: () => _waehleGeschlossen(tag),
                      onUebernehmen: (bloecke) => _uebernimm(tag, bloecke),
                      onVonTap: (i) => _zeitWaehlen(tag, i, true),
                      onBisTap: (i) => _zeitWaehlen(tag, i, false),
                      onBlockEntfernen: (i) => _blockEntfernen(tag, i),
                      onBlockHinzufuegen: () => _blockHinzufuegen(tag),
                      onWeiter: () => _weiter(tag),
                      onZuklappen: () => setState(() => _aktiv = null),
                    )
                  : _TagZeile(
                      tag: tag,
                      l10n: l10n,
                      offen: _istOffen(tag),
                      festgelegt: _istFestgelegt(tag),
                      bloecke: _state.zeiten[tag]!,
                      onTap: () => _oeffneTag(tag),
                    ),
            ),
        ],
      ),
    );
  }
}

/// Eingeklappte Tageszeile — zeigt den Zustand, tippbar zum Aufklappen.
class _TagZeile extends StatelessWidget {
  const _TagZeile({
    required this.tag,
    required this.l10n,
    required this.offen,
    required this.festgelegt,
    required this.bloecke,
    required this.onTap,
  });

  final Wochentag tag;
  final AppLocalizations l10n;
  final bool offen;
  final bool festgelegt;
  final List<TimeBlock> bloecke;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final kurz = OpenStatusService.wochentagKurz(tag, l10n);

    final String text;
    final Color textFarbe;
    if (offen) {
      text = bloecke.map((b) => b.toString()).join(' · ');
      textFarbe = col.ink;
    } else if (festgelegt) {
      text = l10n.statusGeschlossen;
      textFarbe = col.muted;
    } else {
      text = l10n.qeNochFestlegen;
      textFarbe = col.muted;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: festgelegt ? col.surface : Colors.transparent,
          border: Border.all(
            color: festgelegt ? col.line : col.line.withValues(alpha: 0.6),
            style: festgelegt ? BorderStyle.solid : BorderStyle.none,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        foregroundDecoration: festgelegt
            ? null
            : _DashedBorder(color: col.line, radius: 12),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(kurz,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: festgelegt ? col.ink : col.muted)),
            ),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: textFarbe,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ),
            Icon(festgelegt ? Icons.edit_outlined : Icons.add,
                size: 17, color: col.muted),
          ],
        ),
      ),
    );
  }
}

/// Aufgeklappter Tag — der eine Editor (Segment, Blöcke, „Wie …").
class _TagEditor extends StatelessWidget {
  const _TagEditor({
    required this.tag,
    required this.l10n,
    required this.offen,
    required this.festgelegt,
    required this.bloecke,
    required this.vorschlaege,
    required this.naechster,
    required this.onGeoeffnet,
    required this.onGeschlossen,
    required this.onUebernehmen,
    required this.onVonTap,
    required this.onBisTap,
    required this.onBlockEntfernen,
    required this.onBlockHinzufuegen,
    required this.onWeiter,
    required this.onZuklappen,
  });

  final Wochentag tag;
  final AppLocalizations l10n;
  final bool offen;
  final bool festgelegt;
  final List<TimeBlock> bloecke;

  /// Distinct Kopiervorlagen anderer Tage (Quelltag → dessen Blöcke).
  final List<MapEntry<Wochentag, List<TimeBlock>>> vorschlaege;
  final Wochentag? naechster;
  final VoidCallback onGeoeffnet;
  final VoidCallback onGeschlossen;
  final ValueChanged<List<TimeBlock>> onUebernehmen;
  final ValueChanged<int> onVonTap;
  final ValueChanged<int> onBisTap;
  final ValueChanged<int> onBlockEntfernen;
  final VoidCallback onBlockHinzufuegen;
  final VoidCallback onWeiter;
  final VoidCallback onZuklappen;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final geschlossenAktiv = festgelegt && bloecke.isEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(OpenStatusService.wochentagLang(tag, l10n),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: col.ink)),
              const Spacer(),
              InkWell(
                onTap: onZuklappen,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: col.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              _SegChip(
                label: l10n.qeGeoeffnet,
                selected: offen,
                onTap: onGeoeffnet,
              ),
              const SizedBox(width: 8),
              _SegChip(
                label: l10n.qeGeschlossen,
                selected: geschlossenAktiv,
                onTap: onGeschlossen,
              ),
            ],
          ),
          if (offen) ...[
            const SizedBox(height: 12),
            if (vorschlaege.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7, left: 1),
                      child: Text(
                        l10n.qeUebernehmenTitel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: col.muted,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final v in vorschlaege)
                          _WieChip(
                            label: l10n.qeWieTag(
                                OpenStatusService.wochentagLang(v.key, l10n)),
                            onTap: () => onUebernehmen(v.value),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            for (var i = 0; i < bloecke.length; i++) ...[
              _BlockRow(
                block: bloecke[i],
                oeffnetLabel: l10n.qeOeffnet,
                schliesstLabel: l10n.qeSchliesst,
                entfernenTooltip: l10n.qeBlockEntfernen,
                zeigeEntfernen: bloecke.length > 1,
                onVonTap: () => onVonTap(i),
                onBisTap: () => onBisTap(i),
                onEntfernen: () => onBlockEntfernen(i),
              ),
              const SizedBox(height: 9),
            ],
            TextButton(
              onPressed: onBlockHinzufuegen,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
              child: Text(l10n.qeWeitererBlock,
                  style: TextStyle(color: col.primaryInk, fontSize: 13)),
            ),
          ],
          if (festgelegt) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onWeiter,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(naechster != null
                    ? l10n.qeWeiterZu(
                        OpenStatusService.wochentagLang(naechster!, l10n))
                    : l10n.qeFertig),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegChip extends StatelessWidget {
  const _SegChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : col.card,
            border: Border.all(
                color: selected ? AppColors.primary : col.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : col.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _WieChip extends StatelessWidget {
  const _WieChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.content_copy_outlined, size: 14, color: col.primaryInk),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: col.primaryInk)),
          ],
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
    required this.zeigeEntfernen,
    required this.onVonTap,
    required this.onBisTap,
    required this.onEntfernen,
  });

  final TimeBlock block;
  final String oeffnetLabel;
  final String schliesstLabel;
  final String entfernenTooltip;
  final bool zeigeEntfernen;
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('–', style: TextStyle(color: context.col.muted)),
        ),
        Expanded(
            child: _ZeitZelle(
                label: schliesstLabel, zeit: block.bis, onTap: onBisTap)),
        SizedBox(
          width: 34,
          child: zeigeEntfernen
              ? IconButton(
                  onPressed: onEntfernen,
                  tooltip: entfernenTooltip,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close,
                      color: AppColors.danger, size: 18),
                )
              : null,
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
    final col = context.col;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: col.surface,
          border: Border.all(color: col.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: col.muted)),
            Text(zeit.alsString, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

/// Gestrichelter Rahmen für „noch festlegen"-Zeilen (dezent).
class _DashedBorder extends Decoration {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DashedPainter(color, radius);
}

class _DashedPainter extends BoxPainter {
  _DashedPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final rect = offset & cfg.size!;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, (d + dash).clamp(0, metric.length)), paint);
        d += dash + gap;
      }
    }
  }
}
