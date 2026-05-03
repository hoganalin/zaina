import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/onboarding_api.dart';
import '../../models/channel.dart';
import '../../models/interest.dart';
import '../../models/self_view.dart';
import '../../theme/zaina_theme.dart';
import '../../widgets/paper_background.dart';
import '../../widgets/sun_ray_background.dart';
import '../../widgets/zaina_logo.dart';
import '../sign_in/auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _stepCount = 4;

  final _pageController = PageController();
  int _step = 0;

  late final TextEditingController _nicknameCtrl;
  final _usernameCtrl = TextEditingController();
  Gender? _gender;
  final _countryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _interestIds = <String>{};
  final _channelIds = <String>{};

  // Username availability state
  bool? _usernameAvailable;
  bool _usernameChecking = false;

  @override
  void initState() {
    super.initState();
    final initialNick = ref.read(authStateProvider).valueOrNull?.nickname ?? '';
    _nicknameCtrl = TextEditingController(text: initialNick);
    _usernameCtrl.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameCtrl.dispose();
    _usernameCtrl.removeListener(_onUsernameChanged);
    _usernameCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _onUsernameChanged() async {
    final value = _usernameCtrl.text.trim();
    if (value.isEmpty) {
      setState(() {
        _usernameAvailable = null;
        _usernameChecking = false;
      });
      return;
    }
    setState(() {
      _usernameChecking = true;
      _usernameAvailable = null;
    });
    final ok = await ref
        .read(authStateProvider.notifier)
        .checkUsernameAvailable(value);
    if (!mounted || _usernameCtrl.text.trim() != value) return;
    setState(() {
      _usernameChecking = false;
      _usernameAvailable = ok;
    });
  }

  void _next() {
    if (_step < _stepCount - 1) {
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

  bool get _canAdvanceFromCurrentStep {
    switch (_step) {
      case 0: // nickname
        return _nicknameCtrl.text.trim().isNotEmpty;
      case 1: // username — optional, but if filled must be available
        final v = _usernameCtrl.text.trim();
        if (v.isEmpty) return true;
        return _usernameAvailable == true;
      case 2: // interests — always allow
      case 3: // channels — always allow
        return true;
      default:
        return false;
    }
  }

  bool get _canSubmit =>
      _nicknameCtrl.text.trim().isNotEmpty &&
      (_usernameCtrl.text.trim().isEmpty || _usernameAvailable == true);

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final username = _usernameCtrl.text.trim();
    await ref.read(authStateProvider.notifier).submitOnboarding(
          nickname: _nicknameCtrl.text.trim(),
          username: username.isEmpty ? null : username,
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
      body: PaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              _StepHeader(step: _step, onBack: _step == 0 ? null : _back),
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
                    _UsernameStep(
                      controller: _usernameCtrl,
                      checking: _usernameChecking,
                      available: _usernameAvailable,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '送出失敗：${authState.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : _step < _stepCount - 1
                            ? (_canAdvanceFromCurrentStep ? _next : null)
                            : (_canSubmit ? _submit : null),
                    child: Text(
                      _step < _stepCount - 1
                          ? '下一步'
                          : (isSubmitting ? '送出中…' : '完成'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.onBack});
  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final labels = ['暱稱', '帳號名稱', '興趣', '看板'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 18),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: ZainaPalette.inkBlack,
                onPressed: onBack,
              ),
              const Spacer(),
              const Text(
                '在哪 ZAINA',
                style: TextStyle(
                  color: ZainaPalette.brickRedDeep,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: List.generate(labels.length, (i) {
                final isActive = i == step;
                final isDone = i < step;
                final color = isDone
                    ? ZainaPalette.postboxGreen
                    : isActive
                        ? ZainaPalette.brickRed
                        : ZainaPalette.bobaBrown;
                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (i > 0)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i <= step
                                    ? ZainaPalette.postboxGreen
                                    : ZainaPalette.bobaBrown.withValues(alpha: 0.3),
                              ),
                            ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color:
                                  isDone ? ZainaPalette.postboxGreen : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 2),
                            ),
                            child: isDone
                                ? const Icon(Icons.check,
                                    size: 12, color: Colors.white)
                                : null,
                          ),
                          if (i < labels.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i < step
                                    ? ZainaPalette.postboxGreen
                                    : ZainaPalette.bobaBrown.withValues(alpha: 0.3),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const Text(
          '哩厚！說一下你自己',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ZainaPalette.inkBlack,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '認親第一步就是認家鄉呀～',
          style: TextStyle(color: ZainaPalette.bobaBrownDeep, fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: nicknameCtrl,
          decoration: const InputDecoration(labelText: '暱稱（必填）'),
          onChanged: (_) => onChanged(),
          maxLength: 40,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Gender>(
          initialValue: gender,
          decoration: const InputDecoration(labelText: '性別（選填）'),
          items: const [
            DropdownMenuItem(value: Gender.male, child: Text('男')),
            DropdownMenuItem(value: Gender.female, child: Text('女')),
            DropdownMenuItem(value: Gender.nonBinary, child: Text('非二元')),
          ],
          onChanged: onGenderChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: countryCtrl,
                decoration: const InputDecoration(labelText: '國家'),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: '城市'),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UsernameStep extends StatelessWidget {
  const _UsernameStep({
    required this.controller,
    required this.checking,
    required this.available,
  });
  final TextEditingController controller;
  final bool checking;
  final bool? available;

  @override
  Widget build(BuildContext context) {
    final value = controller.text.trim();
    final showAvailable = !checking && available == true && value.isNotEmpty;
    final showTaken = !checking && available == false && value.isNotEmpty;
    final invalidFormat =
        value.isNotEmpty && !RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(value);

    String? helper;
    Color helperColor = ZainaPalette.bobaBrownDeep;
    if (checking) {
      helper = '檢查中…';
    } else if (invalidFormat) {
      helper = '3-20 個字元，僅限英數與底線';
      helperColor = Colors.red;
    } else if (showAvailable) {
      helper = '可使用';
      helperColor = ZainaPalette.postboxGreen;
    } else if (showTaken) {
      helper = '已被使用';
      helperColor = Colors.red;
    } else {
      helper = '帳號名稱無法更換，是你的身份識別。可跳過';
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const Text(
          '輸入帳號名稱',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ZainaPalette.inkBlack,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '個人頁的網址會用到（@username）。可以跳過，之後在「我」→ 編輯也能設。',
          style: TextStyle(color: ZainaPalette.bobaBrownDeep, fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: '帳號名稱',
            prefixText: '@ ',
            helperText: helper,
            helperStyle: TextStyle(color: helperColor),
            suffixIcon: checking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : showAvailable
                    ? const Icon(Icons.check_circle,
                        color: ZainaPalette.postboxGreen)
                    : showTaken || invalidFormat
                        ? const Icon(Icons.error_outline, color: Colors.red)
                        : null,
          ),
          maxLength: 20,
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const Text(
              '你喜歡什麼？',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ZainaPalette.inkBlack,
              ),
            ),
            const SizedBox(height: 24),
            if (active.isNotEmpty) ...[
              const Text('動態類',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ZainaPalette.brickRedDeep,
                  )),
              const SizedBox(height: 8),
              _ChipWrap(
                items: active,
                selected: selectedIds,
                onToggle: onToggle,
              ),
              const SizedBox(height: 24),
            ],
            if (staticInterests.isNotEmpty) ...[
              const Text('靜態類',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ZainaPalette.brickRedDeep,
                  )),
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const Text(
            '想關注哪些看板？',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ZainaPalette.inkBlack,
            ),
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
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) => onToggle(),
        title: Text('${channel.icon ?? ''}  ${channel.name}'),
        subtitle: channel.description == null ? null : Text(channel.description!),
      ),
    );
  }
}

/// Standalone "歡迎光臨" finish screen — pushed after submitOnboarding succeeds
/// so the router naturally redirects to /home and we stop here briefly.
class OnboardingDoneScreen extends StatelessWidget {
  const OnboardingDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                height: 200,
                child: SunRayBackground(
                  maxRadius: 200,
                  child: const WelcomeSignboard(size: 50),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '哩厚！歡迎回家',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ZainaPalette.inkBlack,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 36),
                child: Text(
                  '說不定能交到相伴一生的好友喔！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ZainaPalette.bobaBrownDeep,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('開啟探索'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
