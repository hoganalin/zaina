import 'package:flutter/material.dart';

import '../models/feed_post.dart';
import '../theme/zaina_theme.dart';
import 'sun_ray_background.dart';

/// 招牌看板-styled post card sized for a 2-column masonry grid. Two flavours:
///  - image-flavour (post.imageUrl set): square photo + overlaid bubble-tea
///    stamp + caption + tag row
///  - signboard-flavour (no image): coloured panel with sun-ray + bubble-tea
///    stamp + caption + tag row
class SignboardCard extends StatelessWidget {
  const SignboardCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  final FeedPost post;
  final VoidCallback onTap;

  static List<String> _stampChars(String title) {
    return title.runes
        .map((r) => String.fromCharCode(r))
        .where((c) => c.trim().isNotEmpty)
        .take(3)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final stamp = _stampChars(post.title);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: ZainaPalette.paperCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ZainaPalette.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: hasImage
                      ? _ImageStamp(imageUrl: post.imageUrl!, chars: stamp)
                      : _SignboardArt(chars: stamp, channelName: post.channel.name),
                ),
              ),
              _CardFooter(post: post),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageStamp extends StatelessWidget {
  const _ImageStamp({required this.imageUrl, required this.chars});
  final String imageUrl;
  final List<String> chars;

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
        // Subtle dark scrim so stamp pops on bright photos
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.18),
              ],
            ),
          ),
        ),
        Center(
          child: BubbleTeaStamp(
            chars: chars,
            circleSize: 38,
            color: ZainaPalette.brickRed,
          ),
        ),
      ],
    );
  }
}

class _SignboardArt extends StatelessWidget {
  const _SignboardArt({required this.chars, required this.channelName});
  final List<String> chars;
  final String channelName;

  @override
  Widget build(BuildContext context) {
    final useGreen = channelName.codeUnits.fold(0, (a, b) => a + b) % 2 == 0;
    final accent =
        useGreen ? ZainaPalette.postboxGreen : ZainaPalette.brickRed;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.20),
            accent.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: SunRayBackground(
        maxRadius: 220,
        rayCount: 18,
        color: accent,
        child: Center(
          child: BubbleTeaStamp(
            chars: chars,
            circleSize: 40,
            color: accent,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.remove_red_eye_outlined,
                size: 12,
                color: ZainaPalette.bobaBrownDeep,
              ),
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
