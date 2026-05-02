import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_post.dart';
import 'dio_client.dart';

Future<List<FeedPost>> _fetchFeed(String path) async {
  final res = await dio.get<Map<String, dynamic>>(path);
  final list = res.data!['posts'] as List<dynamic>;
  return list
      .map((json) => FeedPost.fromJson(json as Map<String, dynamic>))
      .toList();
}

final followingFeedProvider = FutureProvider<List<FeedPost>>(
  (ref) => _fetchFeed('/api/feed/following'),
);

final cityFeedProvider = FutureProvider<List<FeedPost>>(
  (ref) => _fetchFeed('/api/feed/city'),
);
