import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import 'dio_client.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final res = await dio.get<Map<String, dynamic>>('/api/notifications');
  final list = res.data!['notifications'] as List<dynamic>;
  return list
      .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
      .toList();
});
