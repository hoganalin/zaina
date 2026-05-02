import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

enum ConversationStatus {
  @JsonValue('message_request')
  messageRequest,
  @JsonValue('active')
  active,
}

@freezed
class ConversationOther with _$ConversationOther {
  const factory ConversationOther({
    required String id,
    required String nickname,
    String? avatarUrl,
  }) = _ConversationOther;

  factory ConversationOther.fromJson(Map<String, dynamic> json) =>
      _$ConversationOtherFromJson(json);
}

@freezed
class ConversationSummary with _$ConversationSummary {
  const factory ConversationSummary({
    required String id,
    required ConversationStatus status,
    required DateTime lastMessageAt,
    required ConversationOther other,
    ChatMessage? lastMessage,
  }) = _ConversationSummary;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      _$ConversationSummaryFromJson(json);
}
