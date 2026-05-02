import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/onboarding_api.dart';
import '../../models/channel.dart';
import '../../models/interest.dart';
import '../../models/self_view.dart';
import '../sign_in/auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  late final TextEditingController _nicknameCtrl;
  Gender? _gender;
  final _countryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _interestIds = <String>{};
  final _channelIds = <String>{};

  @override
  void initState() {
    super.initState();
    final initialNick = ref.read(authStateProvider).valueOrNull?.nickname ?? '';
    _nicknameCtrl = TextEditingController(text: initialNick);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _back() {
    if (_step > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  bool get _canSubmit => _nicknameCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    await ref.read(authStateProvider.notifier).submitOnboarding(
          nickname: _nicknameCtrl.text.trim(),
          gender: _gender,
          country: _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
          city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
          interestIds: _interestIds,
          channelIds: _channelIds,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isSubmitting = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('歡迎 (${_step + 1}/3)'),
        leading: _step == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _back,
              ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / 3),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _ProfileStep(
                  nicknameCtrl: _nicknameCtrl,
                  countryCtrl: _countryCtrl,
                  cityCtrl: _cityCtrl,
                  gender: _gender,
                  onGenderChanged: (g) => setState(() => _gender = g),
                  onChanged: () => setState(() {}),
                ),
                _InterestsStep(
                  selectedIds: _interestIds,
                  onToggle: (id) => setState(() {
                    if (!_interestIds.add(id)) _interestIds.remove(id);
                  }),
                ),
                _ChannelsStep(
                  selectedIds: _channelIds,
                  onToggle: (id) => setState(() {
                    if (!_channelIds.add(id)) _channelIds.remove(id);
                  }),
                ),
              ],
            ),
          ),
          if (authState.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '送出失敗：${authState.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSubmitting
                    ? null
                    : _step < 2
                        ? (_canSubmit || _step != 0 ? _next : null)
                        : (_canSubmit ? _submit : null),
                child: Text(
                  _step < 2 ? '下一步' : (isSubmitting ? '送出中…' : '完成'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.nicknameCtrl,
    required this.countryCtrl,
    required this.cityCtrl,
    required this.gender,
    required this.onGenderChanged,
    required this.onChanged,
  });

  final TextEditingController nicknameCtrl;
  final TextEditingController countryCtrl;
  final TextEditingController cityCtrl;
  final Gender? gender;
  final ValueChanged<Gender?> onGenderChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          '說一下你自己',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: nicknameCtrl,
          decoration: const InputDecoration(
            labelText: '暱稱（必填）',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => onChanged(),
          maxLength: 40,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Gender>(
          initialValue: gender,
          decoration: const InputDecoration(
            labelText: '性別（選填）',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: Gender.male, child: Text('男')),
            DropdownMenuItem(value: Gender.female, child: Text('女')),
            DropdownMenuItem(value: Gender.nonBinary, child: Text('非二元')),
          ],
          onChanged: onGenderChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: countryCtrl,
          decoration: const InputDecoration(
            labelText: '居住國家（選填）',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: cityCtrl,
          decoration: const InputDecoration(
            labelText: '居住城市（選填）',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _InterestsStep extends ConsumerWidget {
  const _InterestsStep({
    required this.selectedIds,
    required this.onToggle,
  });

  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interestsAsync = ref.watch(interestsProvider);
    return interestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('載入興趣失敗：$e')),
      data: (interests) {
        final active = interests
            .where((i) => i.category == InterestCategory.active)
            .toList();
        final staticInterests = interests
            .where((i) => i.category == InterestCategory.staticCategory)
            .toList();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              '你喜歡什麼？',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            if (active.isNotEmpty) ...[
              const Text('動態類', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _ChipWrap(
                items: active,
                selected: selectedIds,
                onToggle: onToggle,
              ),
              const SizedBox(height: 24),
            ],
            if (staticInterests.isNotEmpty) ...[
              const Text('靜態類', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _ChipWrap(
                items: staticInterests,
                selected: selectedIds,
                onToggle: onToggle,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  final List<Interest> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items
          .map(
            (i) => FilterChip(
              label: Text(i.name),
              selected: selected.contains(i.id),
              onSelected: (_) => onToggle(i.id),
            ),
          )
          .toList(),
    );
  }
}

class _ChannelsStep extends ConsumerWidget {
  const _ChannelsStep({
    required this.selectedIds,
    required this.onToggle,
  });

  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);
    return channelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('載入看板失敗：$e')),
      data: (channels) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '你想關注哪些看板？',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          ...channels.map((ch) => _ChannelTile(
                channel: ch,
                selected: selectedIds.contains(ch.id),
                onToggle: () => onToggle(ch.id),
              )),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.channel,
    required this.selected,
    required this.onToggle,
  });

  final Channel channel;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) => onToggle(),
        title: Text(channel.name),
        subtitle: channel.description == null ? null : Text(channel.description!),
      ),
    );
  }
}
