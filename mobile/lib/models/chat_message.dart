import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String conversationId,
    required String senderId,
    required String body,
    DateTime? readAt,
    required DateTime createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
