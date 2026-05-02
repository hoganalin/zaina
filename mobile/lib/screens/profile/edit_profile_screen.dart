import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/users_api.dart';
import '../../models/self_view.dart';
import '../sign_in/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _avatarCtrl;
  Gender? _gender;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    _nicknameCtrl = TextEditingController(text: user?.nickname ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _countryCtrl = TextEditingController(text: user?.country ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _avatarCtrl = TextEditingController(text: user?.avatarUrl ?? '');
    _gender = user?.gender;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(usersApiProvider).patchMe(
            nickname: _nicknameCtrl.text.trim(),
            gender: _gender,
            country: _countryCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            avatarUrl: _avatarCtrl.text.trim().isEmpty
                ? null
                : _avatarCtrl.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯個人資料'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '儲存中…' : '儲存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nicknameCtrl,
            decoration: const InputDecoration(
              labelText: '暱稱',
              border: OutlineInputBorder(),
            ),
            maxLength: 40,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Gender>(
            initialValue: _gender,
            decoration: const InputDecoration(
              labelText: '性別',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: Gender.male, child: Text('男')),
              DropdownMenuItem(value: Gender.female, child: Text('女')),
              DropdownMenuItem(value: Gender.nonBinary, child: Text('非二元')),
            ],
            onChanged: (g) => setState(() => _gender = g),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioCtrl,
            decoration: const InputDecoration(
              labelText: '自我介紹',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _avatarCtrl,
            decoration: const InputDecoration(
              labelText: '頭像 URL（選填）',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text('儲存失敗：$_error',
                style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}
