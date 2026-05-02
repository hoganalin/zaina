import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/chat_message.dart';
import 'dio_client.dart';

class IncomingMessage {
  IncomingMessage({required this.conversationId, required this.message});
  final String conversationId;
  final ChatMessage message;
}

class ChatSocket {
  ChatSocket._();

  io.Socket? _socket;
  final _events = StreamController<IncomingMessage>.broadcast();

  Stream<IncomingMessage> get events => _events.stream;

  static String _baseUrl() {
    return dio.options.baseUrl;
  }

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await user.getIdToken();
    if (token == null) return;

    _socket?.dispose();
    final socket = io.io(
      _baseUrl(),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
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
  }
}

final chatSocketProvider = Provider<ChatSocket>((ref) {
  final socket = ChatSocket._();
  ref.onDispose(socket.disconnect);
  return socket;
});
