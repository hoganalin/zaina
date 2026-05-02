import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';
import 'dio_client.dart';
import 'feed_api.dart';

final channelsListProvider = FutureProvider<List<ChannelWithFollow>>(
  (ref) async {
    final res = await dio.get<Map<String, dynamic>>('/api/channels');
    final list = res.data!['channels'] as List<dynamic>;
    return list
        .map((j) => ChannelWithFollow.fromJson(j as Map<String, dynamic>))
        .toList();
  },
);

class ChannelsApi {
  ChannelsApi(this._ref);
  final Ref _ref;

  Future<void> follow(String channelId) async {
    await dio.post('/api/channels/$channelId/follow');
    _ref.invalidate(channelsListProvider);
    _ref.invalidate(followingFeedProvider);
  }

  Future<void> unfollow(String channelId) async {
    await dio.delete('/api/channels/$channelId/follow');
    _ref.invalidate(channelsListProvider);
    _ref.invalidate(followingFeedProvider);
  }
}

final channelsApiProvider = Provider<ChannelsApi>((ref) => ChannelsApi(ref));

class ChannelWithFollow {
  ChannelWithFollow({required this.channel, required this.isFollowing});
  final Channel channel;
  final bool isFollowing;

  factory ChannelWithFollow.fromJson(Map<String, dynamic> json) {
    return ChannelWithFollow(
      channel: Channel.fromJson(json),
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }
}
