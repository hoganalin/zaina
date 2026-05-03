import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/verifications_api.dart';
import '../../theme/zaina_theme.dart';
import '../../widgets/paper_background.dart';
import '../sign_in/auth_providers.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  IdentityType _type = IdentityType.student;
  final _imageUrlCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final url = _imageUrlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(verificationsApiProvider).submit(
            identityType: _type,
            imageUrl: url,
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
    final isVerified = ref.watch(authStateProvider).valueOrNull?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('身份驗證')),
      body: PaperBackground(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isVerified)
            Card(
              color: ZainaPalette.postboxGreenSoft,
              child: const ListTile(
                leading: Icon(Icons.verified, color: ZainaPalette.postboxGreen),
                title: Text('已驗證', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('你的個人頁面已標示驗證徽章'),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            '上傳學生證或員工證的清晰照片完成驗證。',
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<IdentityType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: '身份類型',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: IdentityType.student,
                child: Text('學生'),
              ),
              DropdownMenuItem(
                value: IdentityType.employee,
                child: Text('在職'),
              ),
            ],
            onChanged: (v) => setState(() => _type = v ?? IdentityType.student),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imageUrlCtrl,
            decoration: const InputDecoration(
              labelText: '證件圖片 URL',
              helperText: 'v1 暫不支援直接上傳，請貼一個圖片連結',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text('送出失敗：$_error',
                style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? '送出中…' : '送出驗證'),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '審核機制',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'v1 為 portfolio 版，後台審核流程是模擬的（即時通過）。'
                    '正式版會接 ISIC / 學校 / 雇主驗證 API。',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }
}
