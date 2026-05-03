import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../api/feed_api.dart';
import '../../models/feed_post.dart';
import '../../theme/zaina_theme.dart';
import '../../widgets/paper_background.dart';
import '../../widgets/signboard_card.dart';
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
          leadingWidth: 56,
          leading: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Center(
              child: Text('🧋', style: TextStyle(fontSize: 28)),
            ),
          ),
          title: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: ZainaPalette.cardSurface,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: ZainaPalette.hairline),
            ),
            child: TabBar(
              isScrollable: false,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: ZainaPalette.brickRed,
                borderRadius: BorderRadius.circular(40),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: ZainaPalette.paperCream,
              unselectedLabelColor: ZainaPalette.bobaBrownDeep,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              padding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              tabs: [
                const Tab(text: '所有話題'),
                Tab(text: hasCity ? '同城' : '追蹤話題'),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.dashboard_outlined),
              tooltip: '看板',
              onPressed: () => context.push('/channels'),
            ),
          ],
        ),
        body: PaperBackground(
          child: TabBarView(
            children: [
              _FeedTab(
                provider: followingFeedProvider,
                emptyHint: '還沒關注任何看板，先去發掘一下',
              ),
              _FeedTab(
                provider: cityFeedProvider,
                emptyHint: '尚未填寫居住城市，去 我 → 編輯 補上',
              ),
            ],
          ),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      emptyHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ZainaPalette.bobaBrownDeep,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            itemCount: posts.length,
            itemBuilder: (context, i) => SignboardCard(
              post: posts[i],
              onTap: () => context.push('/post/${posts[i].id}'),
            ),
          );
        },
      ),
    );
  }
}
