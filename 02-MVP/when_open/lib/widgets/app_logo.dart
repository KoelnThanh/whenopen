import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Das WhenOpen-Markenzeichen als Vektor — identisch zum App-Icon
/// (Logo B „PinTime"): weißer Karten-Pin mit Zifferblatt-Uhr und grünem
/// Mittelpunkt auf einer Indigo-Verlaufskachel.
///
/// Bewusst **nicht** `Icons.location_on`: der nackte Pin ohne Uhr sah in der
/// Liste/„Über"-Ansicht wie ein Ordner-Icon aus. Die Geometrie ist 1:1 aus
/// `tool/gen_icon.py` (`draw_pin`) portiert, damit In-App-Logo und Launcher-
/// Icon exakt übereinstimmen.
class WhenOpenLogo extends StatelessWidget {
  const WhenOpenLogo({super.key, required this.size, this.withShadow = true});

  /// Kantenlänge der quadratischen Kachel.
  final double size;

  /// Weicher Schlagschatten wie beim bisherigen Header-/„Über"-Logo.
  final bool withShadow;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.30;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDeep],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: AppColors.primaryDeep.withValues(alpha: 0.4),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.11),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        size: Size.square(size),
        painter: _PinUhrPainter(),
      ),
    );
  }
}

/// Zeichnet den weißen Pin + Indigo-Uhr + grünen Mittelpunkt auf die Kachel.
/// Maße als Anteile der Kachelseite — exakt wie `draw_pin` (Kopf bei 0.42·Seite,
/// Radius 0.205·Seite).
class _PinUhrPainter extends CustomPainter {
  // Off-Weiß wie im Icon-Generator (#F6F8FB) — etwas wärmer als reines Weiß.
  static const _weiss = Color(0xFFF6F8FB);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s * 0.5;
    final cy = s * 0.42;
    final r = s * 0.205;
    final rr = r * 0.60; // Uhr-Radius

    final weiss = Paint()
      ..color = _weiss
      ..isAntiAlias = true;

    // Pin-Spitze (Dreieck) unter dem Kopf.
    final spitze = Path()
      ..moveTo(cx - r * 0.64, cy + r * 0.60)
      ..lineTo(cx + r * 0.64, cy + r * 0.60)
      ..lineTo(cx, cy + r * 2.15)
      ..close();
    canvas.drawPath(spitze, weiss);

    // Kopf-Kreis (weiße Fläche).
    canvas.drawCircle(Offset(cx, cy), r, weiss);

    // Uhr-Ring (Indigo).
    canvas.drawCircle(
      Offset(cx, cy),
      rr,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.11
        ..isAntiAlias = true,
    );

    // Zeiger (freundliche 10:10-Stellung), Indigo, runde Enden.
    final zeiger = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, cy - rr * 0.66),
      zeiger,
    ); // Minute nach oben
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + rr * 0.46, cy - rr * 0.30),
      zeiger,
    ); // Stunde oben-rechts

    // Mittelpunkt grün (= „offen"-Akzent, wiederkehrende Mikro-Marke).
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.13,
      Paint()
        ..color = AppColors.open
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_PinUhrPainter oldDelegate) => false;
}
