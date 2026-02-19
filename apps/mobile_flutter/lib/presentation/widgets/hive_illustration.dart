import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated beehive illustration rendered with CustomPainter.
/// Shows a Langstroth hive with honeycomb background and animated bees.
class HiveIllustration extends StatefulWidget {
  final Color queenColor;
  final double? varroaRate;
  final int hiveNumber;

  const HiveIllustration({
    super.key,
    this.queenColor = const Color(0xFFFFA000),
    this.varroaRate,
    this.hiveNumber = 1,
  });

  @override
  State<HiveIllustration> createState() => _HiveIllustrationState();
}

class _HiveIllustrationState extends State<HiveIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _varroaColor {
    final rate = widget.varroaRate;
    if (rate == null) return Colors.transparent;
    if (rate < 1) return Colors.greenAccent;
    if (rate <= 3) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _HivePainter(
          progress: _controller.value,
          queenColor: widget.queenColor,
          varroaColor: _varroaColor,
          hiveNumber: widget.hiveNumber,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _HivePainter extends CustomPainter {
  final double progress;
  final Color queenColor;
  final Color varroaColor;
  final int hiveNumber;

  const _HivePainter({
    required this.progress,
    required this.queenColor,
    required this.varroaColor,
    required this.hiveNumber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background gradient ──────────────────────────────────────────────────
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A0E00), Color(0xFF2D1600), Color(0xFF1A0E00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    _drawHoneycomb(canvas, size);
    _drawHive(canvas, size);
    _drawBees(canvas, size);
  }

  // ── Honeycomb background ─────────────────────────────────────────────────
  void _drawHoneycomb(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = const Color(0xFFFFA000).withAlpha(18)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFFFFA000).withAlpha(35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const r = 18.0;
    final w = r * 2;
    final h = r * math.sqrt(3);

    for (double y = -h; y < size.height + h; y += h) {
      for (double x = -w; x < size.width + w; x += w * 1.5) {
        _hexPath(canvas, Offset(x, y), r, fill, stroke);
        _hexPath(canvas, Offset(x + w * 0.75, y + h / 2), r, fill, stroke);
      }
    }
  }

  void _hexPath(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    final p = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * 60 - 30) * math.pi / 180;
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
  }

  // ── Beehive ───────────────────────────────────────────────────────────────
  void _drawHive(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.60;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy - 30),
      72,
      Paint()
        ..color = const Color(0xFFFFA000).withAlpha(25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    // Base stand
    _box(canvas, cx - 54, cy + 24, 108, 10, const Color(0xFF4E342E),
        const Color(0xFF3E2723));

    // Brood box
    _box(canvas, cx - 46, cy - 16, 92, 42, const Color(0xFFD84315),
        const Color(0xFFBF360C));

    // Upper super
    _box(canvas, cx - 40, cy - 56, 80, 42, const Color(0xFFE64A19),
        const Color(0xFFD84315));

    // Honey super (lighter)
    _box(canvas, cx - 34, cy - 90, 68, 36, const Color(0xFFF4511E),
        const Color(0xFFE64A19));

    // Roof
    final roofPath = Path()
      ..moveTo(cx - 50, cy - 90)
      ..lineTo(cx, cy - 116)
      ..lineTo(cx + 50, cy - 90)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF4E342E));
    canvas.drawPath(
      roofPath,
      Paint()
        ..color = const Color(0xFF3E2723)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Roof cap (flat top strip)
    canvas.drawRect(
      Rect.fromLTWH(cx - 50, cy - 92, 100, 5),
      Paint()..color = const Color(0xFF3E2723),
    );

    // Entrance slot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 20, cy + 18, 40, 8),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF1A0900),
    );

    // Landing board
    canvas.drawRect(
      Rect.fromLTWH(cx - 26, cy + 23, 52, 3),
      Paint()..color = const Color(0xFF6D4C41),
    );

    // Hive number badge
    final tp = TextPainter(
      text: TextSpan(
        text: '#$hiveNumber',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final badgeW = tp.width + 14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 35), width: badgeW, height: 18),
        const Radius.circular(9),
      ),
      Paint()..color = const Color(0xFFFFA000),
    );
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - 44));

    // Queen colour dot
    canvas.drawCircle(Offset(cx + 26, cy - 74), 7,
        Paint()..color = queenColor);
    canvas.drawCircle(
        Offset(cx + 26, cy - 74),
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Varroa indicator
    if (varroaColor != Colors.transparent) {
      canvas.drawCircle(
          Offset(cx - 26, cy - 74), 7, Paint()..color = varroaColor);
      canvas.drawCircle(
          Offset(cx - 26, cy - 74),
          7,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  void _box(Canvas canvas, double x, double y, double w, double h, Color fill,
      Color border) {
    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 3, y + 3, w, h), const Radius.circular(3)),
      Paint()..color = Colors.black.withAlpha(60),
    );
    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      Paint()..color = fill,
    );
    // Wood grain
    final grain = Paint()
      ..color = border.withAlpha(70)
      ..strokeWidth = 0.6;
    for (double gy = y + 9; gy < y + h; gy += 9) {
      canvas.drawLine(Offset(x + 5, gy), Offset(x + w - 5, gy), grain);
    }
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ── Bees ──────────────────────────────────────────────────────────────────
  void _drawBees(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.46;

    _bee(canvas,
        Offset(cx + 92 * math.cos(progress * math.pi * 2),
            cy + 30 * math.sin(progress * math.pi * 2)),
        progress * math.pi * 2);

    _bee(
        canvas,
        Offset(
            cx + 62 * math.cos(-(progress * 1.5 + 0.4) * math.pi * 2),
            cy + 20 * math.sin(-(progress * 1.5 + 0.4) * math.pi * 2)),
        -(progress * 1.5 + 0.4) * math.pi * 2,
        scale: 0.82);

    _bee(
        canvas,
        Offset(cx + 112 * math.cos((progress * 0.7 + 0.6) * math.pi * 2),
            cy - 12 + 22 * math.sin((progress * 0.7 + 0.6) * math.pi * 2)),
        (progress * 0.7 + 0.6) * math.pi * 2,
        scale: 0.72);
  }

  void _bee(Canvas canvas, Offset pos, double angle, {double scale = 1.0}) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle + math.pi / 2);
    canvas.scale(scale);

    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 9, height: 14),
        Paint()..color = const Color(0xFFFFC107));

    final stripe = Paint()..color = const Color(0xFF212121).withAlpha(170);
    for (final dy in [-2.5, 1.5, 5.5]) {
      canvas.drawRect(
          Rect.fromCenter(center: Offset(0, dy), width: 9, height: 2.0),
          stripe);
    }

    final wing = Paint()
      ..color = Colors.white.withAlpha(155)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-8, -4), width: 11, height: 7),
        wing);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(8, -4), width: 11, height: 7),
        wing);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_HivePainter old) =>
      old.progress != progress || old.queenColor != queenColor;
}
