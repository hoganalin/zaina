import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';
import '../models/interest.dart';
import 'dio_client.dart';

final interestsProvider = FutureProvider<List<Interest>>((ref) async {
  final res = await dio.get<Map<String, dynamic>>('/api/interests');
  final list = res.data!['interests'] as List<dynamic>;
  return list
      .map((json) => Interest.fromJson(json as Map<String, dynamic>))
      .toList();
});

final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final res = await dio.get<Map<String, dynamic>>('/api/channels');
  final list = res.data!['channels'] as List<dynamic>;
  return list
      .map((json) => Channel.fromJson(json as Map<String, dynamic>))
      .toList();
});
