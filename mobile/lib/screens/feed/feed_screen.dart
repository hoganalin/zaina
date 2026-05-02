import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/feed_api.dart';
import '../../models/feed_post.dart';
import '../sign_in/auth_providers.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final hasCity = user?.city != null && user!.city!.isNotEmpty;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('在哪 ZAINA'),
          bottom: TabBar(
            tabs: [
              const Tab(text: '我關注'),
              Tab(text: hasCity ? '同城 · ${user.city}' : '同城'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FeedTab(
              provider: followingFeedProvider,
              emptyHint: '還沒關注任何看板',
            ),
            _FeedTab(
              provider: cityFeedProvider,
              emptyHint: '尚未填寫居住城市',
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab({required this.provider, required this.emptyHint});

  final FutureProvider<List<FeedPost>> provider;
  final String emptyHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(provider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(provider),
      child: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 96),
            Center(child: Text('載入失敗：$e')),
          ],
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 96),
                Center(
                  child: Text(
                    emptyHint,
                    style: const TextStyle(color: Colors.black45),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => PostCard(
              post: posts[i],
              onTap: () => context.push('/post/${posts[i].id}'),
            ),
          );
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onTap});

  final FeedPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${post.channel.icon ?? ''}  ${post.channel.name}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  post.city,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              post.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  post.author.nickname,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),
                Icon(post.likedByMe ? Icons.favorite : Icons.favorite_border,
                    size: 14, color: post.likedByMe ? Colors.red : Colors.black45),
                const SizedBox(width: 4),
                Text('${post.likeCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.black54,
                    )),
                const SizedBox(width: 12),
                Icon(Icons.mode_comment_outlined,
                    size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text('${post.commentCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.black54,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
