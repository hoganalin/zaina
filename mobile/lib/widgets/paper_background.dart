import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/zaina_theme.dart';

/// Paper-textured cream background. Cheap programmatic noise — no asset shipped.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaperPainter(),
      child: child,
    );
  }
}

class _PaperPainter extends CustomPainter {
  static final _random = math.Random(42);
  static final List<_Speck> _specks = List.generate(
    240,
    (_) => _Speck(
      dx: _random.nextDouble(),
      dy: _random.nextDouble(),
      r: _random.nextDouble() * 1.4 + 0.4,
      alpha: _random.nextDouble() * 0.05 + 0.02,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = ZainaPalette.paperCream;
    canvas.drawRect(Offset.zero & size, bg);

    final speckPaint = Paint()..style = ui.PaintingStyle.fill;
    for (final s in _specks) {
      speckPaint.color =
          ZainaPalette.bobaBrownDeep.withValues(alpha: s.alpha);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        s.r,
        speckPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPainter oldDelegate) => false;
}

class _Speck {
  _Speck({
    required this.dx,
    required this.dy,
    required this.r,
    required this.alpha,
  });
  final double dx;
  final double dy;
  final double r;
  final double alpha;
}
