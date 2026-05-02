import 'package:freezed_annotation/freezed_annotation.dart';

import 'feed_post.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
class PostComment with _$PostComment {
  const factory PostComment({
    required String id,
    required String postId,
    required String body,
    required DateTime createdAt,
    required FeedPostAuthor author,
  }) = _PostComment;

  factory PostComment.fromJson(Map<String, dynamic> json) =>
      _$PostCommentFromJson(json);
}
