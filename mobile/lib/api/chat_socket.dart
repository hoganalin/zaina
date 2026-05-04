import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/chat_message.dart';
import 'dio_client.dart';

/// Connection state surfaced to UI so the user can see "reconnecting…"
/// instead of silent message-not-sending.
enum ChatConnectionStatus { disconnected, connecting, connected, reconnecting }

class IncomingMessage {
  IncomingMessage({required this.conversationId, required this.message});
  final String conversationId;
  final ChatMessage message;
}

/// Single source of truth for the realtime DM connection.
///
/// Reconnect strategy (per RULE-02 in CLAUDE.md):
///   - backoff 1s → 30s (cap), infinite attempts
///   - refresh the Firebase ID token on every reconnect attempt
///     (tokens expire after ~1h; a stale token would re-auth-fail forever)
///   - server's `io.on('connection')` re-runs auth + re-joins `user:{id}`,
///     so the client does NOT need to re-subscribe after a reconnect
///
/// Any future realtime feature (typing, presence, push stream) MUST reuse this
/// socket and this strategy. Do not open a second socket.
class ChatSocket {
  ChatSocket._();

  io.Socket? _socket;
  final _events = StreamController<IncomingMessage>.broadcast();
  final _status = StreamController<ChatConnectionStatus>.broadcast();
  ChatConnectionStatus _current = ChatConnectionStatus.disconnected;

  Stream<IncomingMessage> get events => _events.stream;
  Stream<ChatConnectionStatus> get status => _status.stream;
  ChatConnectionStatus get currentStatus => _current;

  static String _baseUrl() => dio.options.baseUrl;

  void _setStatus(ChatConnectionStatus next) {
    if (_current == next) return;
    _current = next;
    _status.add(next);
  }

  Future<String?> _freshToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken(true);
  }

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = await _freshToken();
    if (token == null) return;

    _socket?.dispose();
    _setStatus(ChatConnectionStatus.connecting);

    final socket = io.io(
      _baseUrl(),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(0x7fffffff)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .setRandomizationFactor(0.5)
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) => _setStatus(ChatConnectionStatus.connected));
    socket.onDisconnect((_) => _setStatus(ChatConnectionStatus.reconnecting));
    socket.onConnectError((_) => _setStatus(ChatConnectionStatus.reconnecting));

    socket.io.on('reconnect_attempt', (_) async {
      final fresh = await _freshToken();
      if (fresh != null) socket.auth = {'token': fresh};
    });

    socket.on('message:new', (data) {
      if (data is! Map) return;
      _events.add(IncomingMessage(
        conversationId: data['conversationId'] as String,
        message: ChatMessage.fromJson(
          (data['message'] as Map).cast<String, dynamic>(),
        ),
      ));
    });

    socket.connect();
    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _setStatus(ChatConnectionStatus.disconnected);
  }
}

final chatSocketProvider = Provider<ChatSocket>((ref) {
  final socket = ChatSocket._();
  ref.onDispose(socket.disconnect);
  return socket;
});
