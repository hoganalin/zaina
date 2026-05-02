import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../models/feed_post.dart';
import 'dio_client.dart';
import 'feed_api.dart';

final postDetailProvider =
    FutureProvider.family<FeedPost, String>((ref, postId) async {
  final res = await dio.get<Map<String, dynamic>>('/api/posts/$postId');
  return FeedPost.fromJson(res.data!['post'] as Map<String, dynamic>);
});

final postCommentsProvider =
    FutureProvider.family<List<PostComment>, String>((ref, postId) async {
  final res =
      await dio.get<Map<String, dynamic>>('/api/posts/$postId/comments');
  final list = res.data!['comments'] as List<dynamic>;
  return list
      .map((j) => PostComment.fromJson(j as Map<String, dynamic>))
      .toList();
});

class PostsApi {
  PostsApi(this._ref);

  final Ref _ref;

  Future<FeedPost> create({
    required String channelId,
    required String title,
    required String body,
    required String city,
    required String country,
    String? imageUrl,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/api/posts',
      data: {
        'channelId': channelId,
        'title': title,
        'body': body,
        'city': city,
        'country': country,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      },
    );
    final post = FeedPost.fromJson(res.data!['post'] as Map<String, dynamic>);
    _ref.invalidate(followingFeedProvider);
    _ref.invalidate(cityFeedProvider);
    return post;
  }

  Future<({int likeCount, bool likedByMe})> like(String postId) async {
    final res = await dio.post<Map<String, dynamic>>('/api/posts/$postId/like');
    return (
      likeCount: res.data!['likeCount'] as int,
      likedByMe: res.data!['likedByMe'] as bool,
    );
  }

  Future<({int likeCount, bool likedByMe})> unlike(String postId) async {
    final res = await dio.delete<Map<String, dynamic>>('/api/posts/$postId/like');
    return (
      likeCount: res.data!['likeCount'] as int,
      likedByMe: res.data!['likedByMe'] as bool,
    );
  }

  Future<PostComment> addComment(String postId, String body) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/api/posts/$postId/comments',
      data: {'body': body},
    );
    return PostComment.fromJson(res.data!['comment'] as Map<String, dynamic>);
  }
}

final postsApiProvider = Provider<PostsApi>((ref) => PostsApi(ref));
