import 'package:flutter/material.dart';

import '../theme/zaina_theme.dart';

/// The 在哪 dual-circle logo with optional ZAINA wordmark below.
class ZainaLogo extends StatelessWidget {
  const ZainaLogo({super.key, this.size = 96, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final circleSize = size;
    final overlap = circleSize * 0.18;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: circleSize,
          width: circleSize * 2 - overlap,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: _LogoCircle(size: circleSize, char: '在'),
              ),
              Positioned(
                right: 0,
                child: _LogoCircle(size: circleSize, char: '哪'),
              ),
            ],
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.14),
          Text(
            'ZAINA',
            style: TextStyle(
              color: ZainaPalette.postboxGreen,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w900,
              letterSpacing: size * 0.06,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({required this.size, required this.char});
  final double size;
  final String char;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: ZainaPalette.logoBrown,
        shape: BoxShape.circle,
        border: Border.all(color: ZainaPalette.paperCream, width: size * 0.06),
        boxShadow: [
          BoxShadow(
            color: ZainaPalette.brickRedDeep.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: ZainaPalette.paperCream,
            fontSize: size * 0.55,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// "歡迎光臨" 4-character signboard, used on onboarding finish + DM eligibility refusal art.
class WelcomeSignboard extends StatelessWidget {
  const WelcomeSignboard({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    const chars = ['歡', '迎', '光', '臨'];
    return Container(
      decoration: BoxDecoration(
        color: ZainaPalette.postboxGreen,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: ZainaPalette.bobaBrownDeep, width: 2),
      ),
      padding: EdgeInsets.symmetric(horizontal: size * 0.18, vertical: size * 0.16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: chars
            .map((c) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: size * 0.06),
                  child: _SignboardCircle(char: c, size: size),
                ))
            .toList(),
      ),
    );
  }
}

class _SignboardCircle extends StatelessWidget {
  const _SignboardCircle({required this.char, required this.size});
  final String char;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        color: ZainaPalette.brickRed,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
