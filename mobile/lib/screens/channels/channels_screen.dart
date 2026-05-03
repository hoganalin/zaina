import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/channels_api.dart';
import '../../widgets/paper_background.dart';

class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(channelsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('看板')),
      body: PaperBackground(child: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
        data: (rows) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(channelsListProvider),
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _ChannelRow(row: rows[i]),
          ),
        ),
      )),
    );
  }
}

class _ChannelRow extends ConsumerStatefulWidget {
  const _ChannelRow({required this.row});
  final ChannelWithFollow row;

  @override
  ConsumerState<_ChannelRow> createState() => _ChannelRowState();
}

class _ChannelRowState extends ConsumerState<_ChannelRow> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    final api = ref.read(channelsApiProvider);
    try {
      if (widget.row.isFollowing) {
        await api.unfollow(widget.row.channel.id);
      } else {
        await api.follow(widget.row.channel.id);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.row.channel;
    return ListTile(
      leading: Text(
        ch.icon ?? '📌',
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(ch.name),
      subtitle: ch.description == null ? null : Text(ch.description!),
      trailing: FilledButton.tonal(
        onPressed: _busy ? null : _toggle,
        child: Text(widget.row.isFollowing ? '已關注' : '關注'),
      ),
    );
  }
}
