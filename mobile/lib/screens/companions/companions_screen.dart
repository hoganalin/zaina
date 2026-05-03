import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/companions_api.dart';
import '../../models/companion.dart';
import '../../theme/zaina_theme.dart';
import '../../widgets/paper_background.dart';

class CompanionsScreen extends ConsumerWidget {
  const CompanionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companions = ref.watch(dailyCompanionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('夥伴'),
      ),
      body: PaperBackground(
        child: companions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('載入失敗：$e')),
          data: (rows) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(dailyCompanionsProvider),
            child: rows.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 96),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            '還沒推薦對象。先到看板補些興趣或留言互動，明天再來看～',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ZainaPalette.bobaBrownDeep),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: rows.length,
                    itemBuilder: (_, i) =>
                        _CompanionCard(companion: rows[i]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CompanionCard extends ConsumerStatefulWidget {
  const _CompanionCard({required this.companion});
  final Companion companion;

  @override
  ConsumerState<_CompanionCard> createState() => _CompanionCardState();
}

class _CompanionCardState extends ConsumerState<_CompanionCard> {
  bool _busy = false;
  bool _skipped = false;

  Future<void> _follow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(companionsActionsProvider).follow(widget.companion.id);
      messenger.showSnackBar(SnackBar(
        content: Text('已追蹤 ${widget.companion.nickname}'),
        duration: const Duration(milliseconds: 800),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.companion;
    if (_skipped) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: ZainaPalette.brickRed.withValues(alpha: 0.18),
                    backgroundImage: c.avatarUrl != null
                        ? NetworkImage(c.avatarUrl!)
                        : null,
                    child: c.avatarUrl == null
                        ? Text(
                            c.nickname.characters.first,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: ZainaPalette.brickRedDeep,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                c.nickname,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: ZainaPalette.inkBlack,
                                ),
                              ),
                            ),
                            if (c.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  size: 16, color: Colors.blue),
                            ],
                          ],
                        ),
                        if (c.username != null)
                          Text(
                            '@${c.username}',
                            style: const TextStyle(
                              color: ZainaPalette.bobaBrownDeep,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (c.sharedCity && c.city != null)
                    _Pill(
                      icon: Icons.location_on_outlined,
                      label: '同城 · ${c.city}',
                      color: ZainaPalette.postboxGreen,
                    ),
                  if (c.sharedInterestCount > 0)
                    _Pill(
                      icon: Icons.favorite_outline,
                      label: '${c.sharedInterestCount} 個共同興趣',
                      color: ZainaPalette.brickRed,
                    ),
                ],
              ),
              if (c.bio != null && c.bio!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  c.bio!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ZainaPalette.inkBlack,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _skipped = true),
                      child: const Text('略過'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _follow,
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('追蹤'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/profile/${c.id}'),
                  child: const Text('查看完整 profile →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
