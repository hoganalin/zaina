import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/posts_api.dart';
import '../../models/comment.dart';
import '../../models/feed_post.dart';
import '../../widgets/paper_background.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _submittingComment = false;
  bool _likeBusy = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(FeedPost post) async {
    if (_likeBusy) return;
    setState(() => _likeBusy = true);
    final api = ref.read(postsApiProvider);
    try {
      final result = post.likedByMe ? await api.unlike(post.id) : await api.like(post.id);
      ref.invalidate(postDetailProvider(post.id));
      // ignore the result return — invalidate is the source of truth
      // but we use the values for snackbar UX if needed.
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 800),
          content: Text(
            result.likedByMe ? '已加入喜歡（${result.likeCount}）' : '取消喜歡',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _submitComment(String postId) async {
    final body = _commentCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _submittingComment = true);
    try {
      await ref.read(postsApiProvider).addComment(postId, body);
      _commentCtrl.clear();
      ref.invalidate(postCommentsProvider(postId));
      ref.invalidate(postDetailProvider(postId));
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('看貼')),
      body: PaperBackground(child: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
        data: (post) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '${post.channel.icon ?? ''}  ${post.channel.name} · ${post.city}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => context.push('/profile/${post.author.id}'),
                    child: Text(post.author.nickname,
                        style: const TextStyle(
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
                        )),
                  ),
                  const Divider(height: 32),
                  Text(post.body, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post.likedByMe ? Icons.favorite : Icons.favorite_border,
                          color: post.likedByMe ? Colors.red : null,
                        ),
                        onPressed: _likeBusy ? null : () => _toggleLike(post),
                      ),
                      Text('${post.likeCount}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.mode_comment_outlined, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text('${post.commentCount}'),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    '留言',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  commentsAsync.when(
                    loading: () =>
                        const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
                    error: (e, _) => Text('載入留言失敗：$e'),
                    data: (comments) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('還沒有留言，當第一個', style: TextStyle(color: Colors.black45)),
                          ),
                        ...comments.map(_CommentTile.new),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        decoration: const InputDecoration(
                          hintText: '留言…',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submittingComment ? null : () => _submitComment(post.id),
                      child: const Text('送出'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile(this.comment);

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.author.nickname,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(comment.body),
        ],
      ),
    );
  }
}
