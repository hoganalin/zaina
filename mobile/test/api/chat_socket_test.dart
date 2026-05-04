import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zaina/api/chat_socket.dart';

void main() {
  group('ChatConnectionStatus', () {
    test('enum exposes the 4 states the UI needs to render', () {
      expect(ChatConnectionStatus.values, hasLength(4));
      expect(
        ChatConnectionStatus.values.toSet(),
        {
          ChatConnectionStatus.disconnected,
          ChatConnectionStatus.connecting,
          ChatConnectionStatus.connected,
          ChatConnectionStatus.reconnecting,
        },
      );
    });
  });

  group('chatSocketProvider', () {
    test('initial status is disconnected before connect() is called', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final socket = container.read(chatSocketProvider);

      expect(socket.currentStatus, ChatConnectionStatus.disconnected);
    });
  });
}
