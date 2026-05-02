import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_post.freezed.dart';
part 'feed_post.g.dart';

@freezed
class FeedPostChannel with _$FeedPostChannel {
  const factory FeedPostChannel({
    required String id,
    required String slug,
    required String name,
    String? icon,
  }) = _FeedPostChannel;

  factory FeedPostChannel.fromJson(Map<String, dynamic> json) =>
      _$FeedPostChannelFromJson(json);
}

@freezed
class FeedPostAuthor with _$FeedPostAuthor {
  const factory FeedPostAuthor({
    required String id,
    required String nickname,
    String? avatarUrl,
  }) = _FeedPostAuthor;

  factory FeedPostAuthor.fromJson(Map<String, dynamic> json) =>
      _$FeedPostAuthorFromJson(json);
}

@freezed
class FeedPost with _$FeedPost {
  const factory FeedPost({
    required String id,
    required String title,
    required String body,
    required String city,
    required String country,
    String? imageUrl,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(false) bool likedByMe,
    required DateTime createdAt,
    required FeedPostChannel channel,
    required FeedPostAuthor author,
  }) = _FeedPost;

  factory FeedPost.fromJson(Map<String, dynamic> json) =>
      _$FeedPostFromJson(json);
}
