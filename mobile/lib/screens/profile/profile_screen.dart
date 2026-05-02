import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/users_api.dart';
import '../feed/feed_screen.dart';
import '../sign_in/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final isMe = me?.id == userId;
    final userAsync = ref.watch(publicUserProvider(userId));
    final postsAsync = ref.watch(userPostsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人頁'),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '編輯個人資料',
              onPressed: () => context.push('/edit-profile'),
            ),
          if (isMe)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: '登出',
              onPressed: () => ref.read(authStateProvider.notifier).signOut(),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publicUserProvider(userId));
          ref.invalidate(userPostsProvider(userId));
        },
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('載入失敗：$e')),
          data: (user) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(user.nickname.characters.first,
                              style: const TextStyle(fontSize: 24))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.nickname,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (user.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified,
                                    size: 18, color: Colors.blue),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (user.city != null || user.country != null)
                            Text(
                              [user.city, user.country]
                                  .whereType<String>()
                                  .join(', '),
                              style: const TextStyle(color: Colors.black54),
                            ),
                          const SizedBox(height: 6),
                          Text('${user.postCount} 篇文章',
                              style: const TextStyle(color: Colors.black45)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (user.bio != null && user.bio!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(user.bio!),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  isMe ? '我的文章' : '${user.nickname} 的文章',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              postsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('載入文章失敗：$e'),
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('還沒發過文',
                            style: TextStyle(color: Colors.black45)),
                      ),
                    );
                  }
                  return Column(
                    children: posts
                        .map((p) => Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0x14000000),
                                  ),
                                ),
                              ),
                              child: PostCard(
                                post: p,
                                onTap: () => context.push('/post/${p.id}'),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
