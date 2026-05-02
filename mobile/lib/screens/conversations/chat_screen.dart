import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/chat_socket.dart';
import '../../api/conversations_api.dart';
import '../../models/chat_message.dart';
import '../sign_in/auth_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _composerCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<IncomingMessage>? _socketSub;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final api = ref.read(conversationsApiProvider);
    final socket = ref.read(chatSocketProvider);
    try {
      final initial = await api.fetchMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = initial;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
    await socket.connect();
    _socketSub = socket.events.listen((evt) {
      if (evt.conversationId != widget.conversationId) return;
      if (_messages.any((m) => m.id == evt.message.id)) return;
      setState(() => _messages = [..._messages, evt.message]);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final body = _composerCtrl.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await ref
          .read(conversationsApiProvider)
          .send(widget.conversationId, body);
      _composerCtrl.clear();
      if (!mounted) return;
      setState(() => _messages = [..._messages, msg]);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _composerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('對話')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('載入失敗：$_error'))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final mine = me?.id == m.senderId;
                          return _Bubble(message: m, mine: mine);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composerCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: '輸入訊息…',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: const Text('傳'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mine
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.body,
          style: TextStyle(
            color: mine ? theme.colorScheme.onPrimary : null,
          ),
        ),
      ),
    );
  }
}
