import 'package:flutter/material.dart';

import '../models/feed_post.dart';
import '../theme/zaina_theme.dart';
import 'sun_ray_background.dart';

/// 招牌看板-styled post card sized for a 2-column masonry grid.
///
/// Per the deck, each card has three layers:
///  1. Background — either a photo (image flavour) or a solid colour with
///     sun-rays (signboard flavour). Cycles through 4 visual flavours so the
///     wall feels alive.
///  2. A small single-character sticker (讚 / 吃 / 哭 / 微 / 旅 etc) in a red
///     bubble-tea circle, top-left. NOT the title — just a stamp.
///  3. The actual title in a cream rounded "speech bubble" box, centered
///     slightly below the middle, with channel-coloured text.
class SignboardCard extends StatelessWidget {
  const SignboardCard({super.key, required this.post, required this.onTap});

  final FeedPost post;
  final VoidCallback onTap;

  /// Pick a single visual sticker character. Channel-driven where it makes
  /// sense (餐 for food, 賣 for second-hand, etc), falling back to the first
  /// title character.
  static String _stickerChar(FeedPost p) {
    final byChannel = {
      'food': '吃',
      'rent': '住',
      'secondhand': '賣',
      'ticket': '票',
      'travel': '走',
      'travel-buddy': '伴',
      'asia': '亞',
      'spain': '西',
      'europe': '歐',
      'solo-travel': '獨',
      'study': '學',
      'mood': '心',
    };
    final fromChannel = byChannel[p.channel.slug];
    if (fromChannel != null) return fromChannel;
    final first = p.title.runes
        .map((r) => String.fromCharCode(r))
        .firstWhere(
          (c) => c.trim().isNotEmpty,
          orElse: () => '在',
        );
    return first;
  }

  /// Cycle through 4 background flavours to break the visual monotony of an
  /// all-signboard wall. Index = stable hash of post.id.
  int _flavourIndex() {
    final h = post.id.codeUnits.fold(0, (a, b) => a + b);
    return h % 4;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final sticker = _stickerChar(post);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: ZainaPalette.bobaBrown.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: hasImage
                      ? _ImageFlavour(
                          imageUrl: post.imageUrl!,
                          sticker: sticker,
                          title: post.title,
                        )
                      : _SignboardFlavour(
                          flavour: _flavourIndex(),
                          sticker: sticker,
                          title: post.title,
                        ),
                ),
                _CardFooter(post: post),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageFlavour extends StatelessWidget {
  const _ImageFlavour({
    required this.imageUrl,
    required this.sticker,
    required this.title,
  });

  final String imageUrl;
  final String sticker;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: ZainaPalette.bobaBrown.withValues(alpha: 0.2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.18),
              ],
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: _StickerCircle(char: sticker),
        ),
        Center(child: _TitleBox(title: title, accent: ZainaPalette.brickRed)),
      ],
    );
  }
}

class _SignboardFlavour extends StatelessWidget {
  const _SignboardFlavour({
    required this.flavour,
    required this.sticker,
    required this.title,
  });

  /// 0 = red sunburst (celebration card)
  /// 1 = green panel
  /// 2 = yellow signboard with red border (special-topic flag)
  /// 3 = cream paper with sun-ray (gentle)
  final int flavour;
  final String sticker;
  final String title;

  @override
  Widget build(BuildContext context) {
    switch (flavour) {
      case 0:
        return _RedSunburst(sticker: sticker, title: title);
      case 1:
        return _GreenPanel(sticker: sticker, title: title);
      case 2:
        return _YellowSignboard(sticker: sticker, title: title);
      default:
        return _CreamPaper(sticker: sticker, title: title);
    }
  }
}

class _RedSunburst extends StatelessWidget {
  const _RedSunburst({required this.sticker, required this.title});
  final String sticker;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ZainaPalette.brickRed,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SunRayBackground(
            color: ZainaPalette.goldSparkle,
            rayCount: 22,
            maxRadius: 220,
            child: const SizedBox.shrink(),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: _StickerCircle(
              char: sticker,
              fill: ZainaPalette.goldSparkle,
              charColor: ZainaPalette.brickRedDeep,
            ),
          ),
          Center(
            child: Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ZainaPalette.goldSparkle,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.2,
                shadows: [
                  Shadow(
                    color: ZainaPalette.brickRedDeep,
                    offset: Offset(1, 1),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreenPanel extends StatelessWidget {
  const _GreenPanel({required this.sticker, required this.title});
  final String sticker;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ZainaPalette.postboxGreen.withValues(alpha: 0.92),
            ZainaPalette.postboxGreenDeep,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SunRayBackground(
            color: ZainaPalette.goldSparkle.withValues(alpha: 0.4),
            rayCount: 16,
            maxRadius: 200,
            child: const SizedBox.shrink(),
          ),
          Positioned(top: 10, left: 10, child: _StickerCircle(char: sticker)),
          Center(child: _TitleBox(title: title, accent: ZainaPalette.postboxGreenDeep)),
        ],
      ),
    );
  }
}

class _YellowSignboard extends StatelessWidget {
  const _YellowSignboard({required this.sticker, required this.title});
  final String sticker;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ZainaPalette.goldSparkle,
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: ZainaPalette.goldSparkle.withValues(alpha: 0.3),
          border: Border.all(color: ZainaPalette.brickRed, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(top: 6, left: 6, child: _StickerCircle(char: sticker, size: 28)),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ZainaPalette.brickRedDeep,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreamPaper extends StatelessWidget {
  const _CreamPaper({required this.sticker, required this.title});
  final String sticker;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ZainaPalette.paperCream,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SunRayBackground(
            color: ZainaPalette.brickRed.withValues(alpha: 0.18),
            rayCount: 20,
            maxRadius: 200,
            child: const SizedBox.shrink(),
          ),
          Positioned(top: 10, left: 10, child: _StickerCircle(char: sticker)),
          Center(child: _TitleBox(title: title, accent: ZainaPalette.brickRedDeep)),
        ],
      ),
    );
  }
}

class _StickerCircle extends StatelessWidget {
  const _StickerCircle({
    required this.char,
    this.size = 32,
    this.fill = ZainaPalette.brickRed,
    this.charColor = ZainaPalette.paperCream,
  });

  final String char;
  final double size;
  final Color fill;
  final Color charColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: ZainaPalette.paperCream, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: charColor,
            fontSize: size * 0.5,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _TitleBox extends StatelessWidget {
  const _TitleBox({required this.title, required this.accent});
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ZainaPalette.paperCream,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ZainaPalette.paperCream,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined,
                  size: 12, color: ZainaPalette.bobaBrownDeep),
              const SizedBox(width: 3),
              Text(
                '${post.commentCount * 7 + post.likeCount * 3 + 5}',
                style: const TextStyle(
                  color: ZainaPalette.bobaBrownDeep,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                post.likedByMe ? Icons.favorite : Icons.favorite_border,
                size: 12,
                color: post.likedByMe
                    ? ZainaPalette.brickRed
                    : ZainaPalette.bobaBrownDeep,
              ),
              const SizedBox(width: 3),
              Text(
                '${post.likeCount}',
                style: const TextStyle(
                  color: ZainaPalette.bobaBrownDeep,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '#${post.channel.name}  #${post.city}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ZainaPalette.bobaBrownDeep,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
