import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/companion.dart';
import 'dio_client.dart';

final dailyCompanionsProvider = FutureProvider<List<Companion>>((ref) async {
  final res =
      await dio.get<Map<String, dynamic>>('/api/companions/daily?limit=10');
  final list = res.data!['companions'] as List<dynamic>;
  return list
      .map((j) => Companion.fromJson(j as Map<String, dynamic>))
      .toList();
});

class CompanionsActions {
  CompanionsActions(this._ref);
  final Ref _ref;

  Future<void> follow(String userId) async {
    await dio.post('/api/users/$userId/follow');
    _ref.invalidate(dailyCompanionsProvider);
  }
}

final companionsActionsProvider =
    Provider<CompanionsActions>((ref) => CompanionsActions(ref));
