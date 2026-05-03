import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

enum NotificationType {
  @JsonValue('comment_on_my_post')
  commentOnMyPost,
  @JsonValue('new_dm')
  newDm,
  @JsonValue('new_post_in_channel')
  newPostInChannel,
  @JsonValue('new_follower')
  newFollower,
}

@freezed
class NotificationActor with _$NotificationActor {
  const factory NotificationActor({
    required String id,
    required String nickname,
    String? avatarUrl,
  }) = _NotificationActor;

  factory NotificationActor.fromJson(Map<String, dynamic> json) =>
      _$NotificationActorFromJson(json);
}

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationType type,
    required DateTime createdAt,
    required NotificationActor actor,
    Map<String, dynamic>? target,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}
