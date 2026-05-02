import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import 'dio_client.dart';

final conversationsListProvider = FutureProvider<List<ConversationSummary>>(
  (ref) async {
    final res = await dio.get<Map<String, dynamic>>('/api/conversations');
    final list = res.data!['conversations'] as List<dynamic>;
    return list
        .map((j) => ConversationSummary.fromJson(j as Map<String, dynamic>))
        .toList();
  },
);

class ConversationsApi {
  ConversationsApi(this._ref);
  final Ref _ref;

  /// Returns null if backend rejected with 403 (not eligible).
  /// Throws on other errors.
  Future<({String id, ConversationStatus status})?> openWith(String userId) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/api/conversations',
        data: {'userId': userId},
      );
      _ref.invalidate(conversationsListProvider);
      final conv = res.data!['conversation'] as Map<String, dynamic>;
      return (
        id: conv['id'] as String,
        status: _parseStatus(conv['status'] as String),
      );
    } on Exception catch (e) {
      // dio raises DioException; we only special-case 403.
      final dyn = e as dynamic;
      try {
        final statusCode = dyn.response?.statusCode as int?;
        if (statusCode == 403) return null;
      } catch (_) {}
      rethrow;
    }
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/api/conversations/$conversationId/messages',
    );
    final list = res.data!['messages'] as List<dynamic>;
    return list
        .map((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> send(String conversationId, String body) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/api/conversations/$conversationId/messages',
      data: {'body': body},
    );
    _ref.invalidate(conversationsListProvider);
    return ChatMessage.fromJson(res.data!['message'] as Map<String, dynamic>);
  }
}

ConversationStatus _parseStatus(String s) => switch (s) {
      'active' => ConversationStatus.active,
      _ => ConversationStatus.messageRequest,
    };

final conversationsApiProvider =
    Provider<ConversationsApi>((ref) => ConversationsApi(ref));
