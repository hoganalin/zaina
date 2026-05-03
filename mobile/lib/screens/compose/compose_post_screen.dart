import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/onboarding_api.dart';
import '../../api/posts_api.dart';
import '../../models/channel.dart';
import '../../widgets/paper_background.dart';
import '../sign_in/auth_providers.dart';

class ComposePostScreen extends ConsumerStatefulWidget {
  const ComposePostScreen({super.key});

  @override
  ConsumerState<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends ConsumerState<ComposePostScreen> {
  Channel? _channel;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _countryCtrl = TextEditingController(text: user?.country ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _channel != null &&
      _titleCtrl.text.trim().isNotEmpty &&
      _bodyCtrl.text.trim().isNotEmpty &&
      _cityCtrl.text.trim().isNotEmpty &&
      _countryCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(postsApiProvider).create(
            channelId: _channel!.id,
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            country: _countryCtrl.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('發文'),
        actions: [
          TextButton(
            onPressed: _canSubmit && !_submitting ? _submit : null,
            child: Text(_submitting ? '送出中…' : '送出'),
          ),
        ],
      ),
      body: PaperBackground(child: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入看板失敗：$e')),
        data: (channels) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Channel>(
              initialValue: _channel,
              decoration: const InputDecoration(
                labelText: '看板',
                border: OutlineInputBorder(),
              ),
              items: channels
                  .map((ch) => DropdownMenuItem(
                        value: ch,
                        child: Text('${ch.icon ?? ''} ${ch.name}'),
                      ))
                  .toList(),
              onChanged: (ch) => setState(() => _channel = ch),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '標題',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              maxLength: 120,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: '內容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
              maxLines: 8,
              maxLength: 2000,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: '城市',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _countryCtrl,
                    decoration: const InputDecoration(
                      labelText: '國家',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text('送出失敗：$_error',
                  style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      )),
    );
  }
}
