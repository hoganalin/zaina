import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/zaina_theme.dart';

/// Programmatic sun-ray fan radiating from a center point. Used behind the
/// 在哪 logo on splash and behind 歡迎光臨 on the onboarding finish modal,
/// matching the deck's gold radial pattern.
class SunRayBackground extends StatelessWidget {
  const SunRayBackground({
    super.key,
    required this.child,
    this.rayCount = 24,
    this.maxRadius = 360,
    this.color = ZainaPalette.goldSparkle,
  });

  final Widget child;
  final int rayCount;
  final double maxRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _SunRayPainter(
              rayCount: rayCount,
              maxRadius: maxRadius,
              color: color,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _SunRayPainter extends CustomPainter {
  _SunRayPainter({
    required this.rayCount,
    required this.maxRadius,
    required this.color,
  });

  final int rayCount;
  final double maxRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final step = (2 * math.pi) / rayCount;
    final beamWidth = step * 0.32;

    for (var i = 0; i < rayCount; i++) {
      final angle = i * step;
      final p1 = Offset(
        center.dx + math.cos(angle - beamWidth) * 6,
        center.dy + math.sin(angle - beamWidth) * 6,
      );
      final p2 = Offset(
        center.dx + math.cos(angle - beamWidth) * maxRadius,
        center.dy + math.sin(angle - beamWidth) * maxRadius,
      );
      final p3 = Offset(
        center.dx + math.cos(angle + beamWidth) * maxRadius,
        center.dy + math.sin(angle + beamWidth) * maxRadius,
      );
      final p4 = Offset(
        center.dx + math.cos(angle + beamWidth) * 6,
        center.dy + math.sin(angle + beamWidth) * 6,
      );
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SunRayPainter oldDelegate) => false;
}

/// Vertical stack of bubble-tea-style red circles with one Chinese character
/// per circle, matching the deck's 招牌看板 stamp style on image-flavour cards
/// (e.g. "讚 / 早 / 上 / 好").
class BubbleTeaStamp extends StatelessWidget {
  const BubbleTeaStamp({
    super.key,
    required this.chars,
    this.circleSize = 36,
    this.color = ZainaPalette.brickRed,
    this.altColor,
  });

  /// First N characters of the title to stamp. Limit to 3-4 for readability.
  final List<String> chars;
  final double circleSize;
  final Color color;

  /// Optional alternating circle color (used on the 歡迎光臨 modal where
  /// circles flip red/green). Null means single colour.
  final Color? altColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chars.length; i++) ...[
          if (i > 0) SizedBox(height: circleSize * 0.14),
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: (altColor != null && i.isOdd) ? altColor : color,
              shape: BoxShape.circle,
              border: Border.all(
                color: ZainaPalette.paperCream,
                width: circleSize * 0.07,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                chars[i],
                style: TextStyle(
                  color: ZainaPalette.paperCream,
                  fontSize: circleSize * 0.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
