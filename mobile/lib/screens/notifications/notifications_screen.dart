import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/notifications_api.dart';
import '../../models/app_notification.dart';
import '../../theme/zaina_theme.dart';
import '../../widgets/paper_background.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: PaperBackground(
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('載入失敗：$e')),
          data: (rows) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: rows.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 96),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          '還沒有新通知。發點文、留個言，朋友就會冒出來啦',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ZainaPalette.bobaBrownDeep),
                        ),
                      ),
                    ),
                  ])
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _NotifTile(n: rows[i]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.n});
  final AppNotification n;

  String _label() {
    switch (n.type) {
      case NotificationType.commentOnMyPost:
        final title = n.target?['postTitle'] as String? ?? '';
        return '${n.actor.nickname} 在你的「$title」留言';
      case NotificationType.newDm:
        final body = n.target?['body'] as String? ?? '';
        return '${n.actor.nickname}：$body';
      case NotificationType.newPostInChannel:
        final ch = n.target?['channelName'] as String? ?? '';
        final title = n.target?['postTitle'] as String? ?? '';
        return '${n.actor.nickname} 在 $ch 看板發了「$title」';
      case NotificationType.newFollower:
        return '${n.actor.nickname} 追蹤了你';
    }
  }

  IconData _icon() {
    switch (n.type) {
      case NotificationType.commentOnMyPost:
        return Icons.mode_comment_outlined;
      case NotificationType.newDm:
        return Icons.chat_bubble_outline;
      case NotificationType.newPostInChannel:
        return Icons.dashboard_outlined;
      case NotificationType.newFollower:
        return Icons.person_add_alt_1;
    }
  }

  Color _iconColor() {
    switch (n.type) {
      case NotificationType.newDm:
      case NotificationType.newFollower:
        return ZainaPalette.brickRed;
      default:
        return ZainaPalette.postboxGreen;
    }
  }

  void _onTap(BuildContext context) {
    switch (n.type) {
      case NotificationType.commentOnMyPost:
      case NotificationType.newPostInChannel:
        final id = n.target?['postId'] as String?;
        if (id != null) context.push('/post/$id');
      case NotificationType.newDm:
        final id = n.target?['conversationId'] as String?;
        if (id != null) context.push('/chat/$id');
      case NotificationType.newFollower:
        context.push('/profile/${n.actor.id}');
    }
  }

  String _ago() {
    final delta = DateTime.now().difference(n.createdAt);
    if (delta.inDays > 0) return '${delta.inDays}d';
    if (delta.inHours > 0) return '${delta.inHours}h';
    if (delta.inMinutes > 0) return '${delta.inMinutes}m';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _iconColor().withValues(alpha: 0.15),
        backgroundImage: n.actor.avatarUrl != null
            ? NetworkImage(n.actor.avatarUrl!)
            : null,
        child: n.actor.avatarUrl == null
            ? Icon(_icon(), color: _iconColor(), size: 20)
            : null,
      ),
      title: Text(
        _label(),
        style: const TextStyle(fontSize: 14, color: ZainaPalette.inkBlack),
      ),
      trailing: Text(
        _ago(),
        style: const TextStyle(
          fontSize: 11,
          color: ZainaPalette.bobaBrownDeep,
        ),
      ),
      onTap: () => _onTap(context),
    );
  }
}
