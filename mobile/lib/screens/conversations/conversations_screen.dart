import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/conversations_api.dart';
import '../../models/conversation.dart';
import '../../theme/zaina_theme.dart';
import '../../widgets/paper_background.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(conversationsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('訊息')),
      body: PaperBackground(child: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
        data: (rows) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(conversationsListProvider),
          child: rows.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 96),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          '還沒有訊息。先去公開區留言互動，建立私訊資格 →',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ZainaPalette.bobaBrownDeep),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _ConvRow(summary: rows[i]),
                ),
        ),
      )),
    );
  }
}

class _ConvRow extends StatelessWidget {
  const _ConvRow({required this.summary});
  final ConversationSummary summary;

  @override
  Widget build(BuildContext context) {
    final isRequest = summary.status == ConversationStatus.messageRequest;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: ZainaPalette.brickRed.withValues(alpha: 0.15),
        backgroundImage: summary.other.avatarUrl != null
            ? NetworkImage(summary.other.avatarUrl!)
            : null,
        child: summary.other.avatarUrl == null
            ? Text(
                summary.other.nickname.characters.first,
                style: const TextStyle(
                  color: ZainaPalette.brickRedDeep,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Flexible(child: Text(summary.other.nickname)),
          if (isRequest) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('訊息邀請', style: TextStyle(fontSize: 11)),
            ),
          ],
        ],
      ),
      subtitle: summary.lastMessage == null
          ? const Text('尚無對話', style: TextStyle(color: Colors.black45))
          : Text(
              summary.lastMessage!.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: () => context.push('/chat/${summary.id}'),
    );
  }
}
