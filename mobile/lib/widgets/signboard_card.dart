import 'package:flutter/material.dart';

import '../models/feed_post.dart';
import '../theme/zaina_theme.dart';

/// 招牌看板-styled post card. If the post has imageUrl, render image-flavour;
/// otherwise render solid-colour signboard with the post title in bubble-tea
/// circles. Keeps the deck's two visual flavours.
class SignboardCard extends StatelessWidget {
  const SignboardCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  final FeedPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: ZainaPalette.paperCreamSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ZainaPalette.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(post: post),
                if (hasImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.zero,
                      top: Radius.circular(0),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  )
                else
                  _MiniSignboard(title: post.title, channelName: post.channel.name),
                _Body(post: post),
                _Footer(post: post),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          _ChannelChip(name: post.channel.name, icon: post.channel.icon),
          const Spacer(),
          Icon(Icons.location_on_outlined,
              size: 14, color: ZainaPalette.bobaBrownDeep),
          const SizedBox(width: 2),
          Text(
            post.city,
            style: const TextStyle(
              color: ZainaPalette.bobaBrownDeep,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({required this.name, required this.icon});
  final String name;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ZainaPalette.postboxGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${icon ?? ''} $name',
        style: const TextStyle(
          color: ZainaPalette.postboxGreenDeep,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniSignboard extends StatelessWidget {
  const _MiniSignboard({required this.title, required this.channelName});
  final String title;
  final String channelName;

  @override
  Widget build(BuildContext context) {
    // Pick palette per channel name hash so cards differ subtly. Two flavours:
    // brick on cream, or postbox green on cream.
    final useGreen = channelName.codeUnits.fold(0, (a, b) => a + b) % 2 == 0;
    final accent =
        useGreen ? ZainaPalette.postboxGreen : ZainaPalette.brickRed;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Text(
        post.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ZainaPalette.inkBlack,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Row(
        children: [
          Text(
            post.author.nickname,
            style: const TextStyle(
              color: ZainaPalette.bobaBrownDeep,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(
            post.likedByMe ? Icons.favorite : Icons.favorite_border,
            size: 14,
            color: post.likedByMe
                ? ZainaPalette.brickRed
                : ZainaPalette.bobaBrownDeep,
          ),
          const SizedBox(width: 4),
          Text(
            '${post.likeCount}',
            style: const TextStyle(
              color: ZainaPalette.bobaBrownDeep,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.mode_comment_outlined,
            size: 14,
            color: ZainaPalette.bobaBrownDeep,
          ),
          const SizedBox(width: 4),
          Text(
            '${post.commentCount}',
            style: const TextStyle(
              color: ZainaPalette.bobaBrownDeep,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
