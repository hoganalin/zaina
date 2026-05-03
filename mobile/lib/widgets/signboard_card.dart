import 'package:flutter/material.dart';

import '../models/feed_post.dart';
import '../theme/zaina_theme.dart';
import 'sun_ray_background.dart';

/// 招牌看板-styled post card. The deck cycles SIX structurally distinct
/// templates across the masonry wall, each with a different aspect ratio so
/// the grid feels hand-curated, not generated. We pick a template by hashing
/// post.id, so the same post is always the same shape.
///
/// Templates:
///   0  multiStackStickerOnImage  — image + 3 stamps stacked (微/旅/伴)
///   1  stickerCaptionOnImage     — image + 1 sticker + cream caption
///   2  sunburstBigText           — solid red + gold sunburst + big yellow
///                                  hand-painted text (今天 是我生日!!!)
///   3  yellowSignboard           — yellow bg + red border + 「特別話題」
///                                  category label + bold title
///   4  speechBubbleOnPaper       — paper + corner sticker + cream
///                                  speech-bubble title (人也太多了吧!!)
///   5  greenPanelStickerCaption  — green panel + sun-ray + sticker + caption
class SignboardCard extends StatelessWidget {
  const SignboardCard({super.key, required this.post, required this.onTap});

  final FeedPost post;
  final VoidCallback onTap;

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
        .firstWhere((c) => c.trim().isNotEmpty, orElse: () => '在');
    return first;
  }

  static List<String> _stackChars(String title) {
    final cleaned = title.runes
        .map((r) => String.fromCharCode(r))
        .where((c) => c.trim().isNotEmpty)
        .toList();
    return cleaned.take(3).toList();
  }

  /// Multi-stack stamps only make sense for CJK titles (微/旅/伴).
  /// English titles like "Hamilton" produce nonsense (H/a/m), so only the
  /// caption-flavoured templates are used for those.
  static bool _titleIsCjk(String title) {
    final firstThree = title.runes
        .map((r) => String.fromCharCode(r))
        .where((c) => c.trim().isNotEmpty)
        .take(3);
    return firstThree.every((c) {
      final code = c.runes.first;
      return code >= 0x4E00 && code <= 0x9FFF;
    });
  }

  int _hash() => post.id.codeUnits.fold(0, (a, b) => a + b);

  /// Aspect ratio per template, varied to give masonry variety.
  double _aspectRatio(int t) {
    switch (t) {
      case 0:
        return 0.82; // tall — multi-stack stamps
      case 1:
        return 1.0; // square
      case 2:
        return 1.05; // sunburst — slightly squarer than tall
      case 3:
        return 0.78; // yellow signboard — taller (poster shape)
      case 4:
        return 0.9; // speech bubble
      default:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final hash = _hash();

    // Cycle through all six templates regardless of image. Templates 2/3/4/5
    // either ignore the image or fold it in (yellow signboard uses it as a
    // thumbnail inset). This keeps the masonry wall genuinely varied even
    // when every post happens to have an image.
    var template = hash % 6;

    final sticker = _stickerChar(post);
    final stack = _stackChars(post.title);

    // Multi-stack only works for CJK; for non-CJK titles, route to template 1.
    if (template == 0 && !_titleIsCjk(post.title)) {
      template = 1;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: ZainaPalette.bobaBrown.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: _aspectRatio(template),
                  child: switch (template) {
                    0 => hasImage
                        ? _MultiStackOnImage(
                            imageUrl: post.imageUrl!,
                            chars: stack,
                          )
                        : _GreenPanel(sticker: sticker, title: post.title),
                    1 => hasImage
                        ? _StickerCaptionOnImage(
                            imageUrl: post.imageUrl!,
                            sticker: sticker,
                            title: post.title,
                          )
                        : _SpeechBubbleOnPaper(
                            sticker: sticker,
                            title: post.title,
                          ),
                    2 => _SunburstBigText(
                        title: post.title,
                        imageUrl: post.imageUrl,
                      ),
                    3 => _YellowSignboard(
                        title: post.title,
                        label: '特別話題',
                        imageUrl: post.imageUrl,
                      ),
                    4 => _SpeechBubbleOnPaper(
                        sticker: sticker,
                        title: post.title,
                        imageUrl: post.imageUrl,
                      ),
                    _ => _GreenPanel(
                        sticker: sticker,
                        title: post.title,
                        imageUrl: post.imageUrl,
                      ),
                  },
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

// ---------- 0. multi-stack stamps on image ----------

class _MultiStackOnImage extends StatelessWidget {
  const _MultiStackOnImage({required this.imageUrl, required this.chars});
  final String imageUrl;
  final List<String> chars;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(imageUrl, fit: BoxFit.cover, cacheWidth: 360, cacheHeight: 360, errorBuilder: _imgFallback),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < chars.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                _Stamp(char: chars[i], size: 36),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- 1. sticker + cream caption box on image ----------

class _StickerCaptionOnImage extends StatelessWidget {
  const _StickerCaptionOnImage({
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
        Image.network(imageUrl, fit: BoxFit.cover, cacheWidth: 360, cacheHeight: 360, errorBuilder: _imgFallback),
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
        Positioned(top: 10, left: 10, child: _Stamp(char: sticker)),
        Center(
          child: _CreamCaption(
            title: title,
            accent: ZainaPalette.brickRed,
          ),
        ),
      ],
    );
  }
}

// ---------- 2. solid red + sunburst + big bare text (optional image bg) ----------

class _SunburstBigText extends StatelessWidget {
  const _SunburstBigText({required this.title, this.imageUrl});
  final String title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null;
    return Container(
      color: ZainaPalette.brickRed,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              cacheWidth: 360,
              cacheHeight: 360,
              errorBuilder: _imgFallback,
            )
          else
            SunRayBackground(
              color: ZainaPalette.goldSparkle,
              rayCount: 24,
              maxRadius: 240,
              child: const SizedBox.shrink(),
            ),
          if (hasImage)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                title,
                maxLines: 4,
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
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- 3. yellow signboard with red border + category label + thumb ----------

class _YellowSignboard extends StatelessWidget {
  const _YellowSignboard({
    required this.title,
    required this.label,
    this.imageUrl,
  });
  final String title;
  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ZainaPalette.paperCream,
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: ZainaPalette.goldSparkle.withValues(alpha: 0.35),
          border: Border.all(color: ZainaPalette.brickRed, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: ZainaPalette.brickRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: ZainaPalette.paperCream,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (imageUrl != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              cacheWidth: 360,
              cacheHeight: 360,
              errorBuilder: _imgFallback,
            ),
                  ),
                ),
              ),
            ],
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ZainaPalette.brickRedDeep,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
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

// ---------- 4. paper + sticker + speech-bubble title (optional image bg) ----------

class _SpeechBubbleOnPaper extends StatelessWidget {
  const _SpeechBubbleOnPaper({
    required this.sticker,
    required this.title,
    this.imageUrl,
  });
  final String sticker;
  final String title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null;
    return Container(
      color: ZainaPalette.paperCream,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              cacheWidth: 360,
              cacheHeight: 360,
              errorBuilder: _imgFallback,
            )
          else
            SunRayBackground(
              color: ZainaPalette.brickRed.withValues(alpha: 0.18),
              rayCount: 18,
              maxRadius: 200,
              child: const SizedBox.shrink(),
            ),
          if (hasImage)
            Container(color: Colors.black.withValues(alpha: 0.25)),
          Positioned(top: 10, right: 10, child: _Stamp(char: sticker)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: ZainaPalette.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ZainaPalette.brickRed.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ZainaPalette.brickRedDeep,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- 5. green panel + sticker + cream caption (optional image bg) ----------

class _GreenPanel extends StatelessWidget {
  const _GreenPanel({
    required this.sticker,
    required this.title,
    this.imageUrl,
  });
  final String sticker;
  final String title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null;
    return Container(
      decoration: hasImage
          ? null
          : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ZainaPalette.postboxGreen,
                  ZainaPalette.postboxGreenDeep,
                ],
              ),
            ),
      color: hasImage ? ZainaPalette.postboxGreenDeep : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              cacheWidth: 360,
              cacheHeight: 360,
              errorBuilder: _imgFallback,
            )
          else
            SunRayBackground(
              color: ZainaPalette.goldSparkle.withValues(alpha: 0.5),
              rayCount: 16,
              maxRadius: 200,
              child: const SizedBox.shrink(),
            ),
          if (hasImage)
            Container(
              color: ZainaPalette.postboxGreenDeep.withValues(alpha: 0.45),
            ),
          Positioned(top: 10, left: 10, child: _Stamp(char: sticker)),
          Center(
            child: _CreamCaption(
              title: title,
              accent: ZainaPalette.postboxGreenDeep,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- shared widgets ----------

class _Stamp extends StatelessWidget {
  const _Stamp({required this.char, this.size = 32});

  final String char;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ZainaPalette.brickRed,
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
            color: ZainaPalette.paperCream,
            fontSize: size * 0.5,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _CreamCaption extends StatelessWidget {
  const _CreamCaption({required this.title, required this.accent});
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ZainaPalette.paperCream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontSize: 16,
            fontWeight: FontWeight.w900,
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
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _HashtagChip(label: post.channel.name, color: ZainaPalette.brickRed),
              _HashtagChip(label: post.city, color: ZainaPalette.postboxGreen),
            ],
          ),
        ],
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  const _HashtagChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '#$label',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Widget _imgFallback(BuildContext _, Object _, StackTrace? _) {
  return Container(color: ZainaPalette.bobaBrown.withValues(alpha: 0.2));
}
