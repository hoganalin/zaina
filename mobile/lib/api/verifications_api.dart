import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/self_view.dart';
import '../screens/sign_in/auth_providers.dart';
import 'dio_client.dart';

enum IdentityType { student, employee }

String _identityTypeJson(IdentityType t) =>
    t == IdentityType.student ? 'student' : 'employee';

class VerificationsApi {
  VerificationsApi(this._ref);
  final Ref _ref;

  Future<void> submit({
    required IdentityType identityType,
    required String imageUrl,
  }) async {
    await dio.post(
      '/api/verifications',
      data: {
        'identityType': _identityTypeJson(identityType),
        'imageUrl': imageUrl,
      },
    );
    // Backend marks user.isVerified=true. Refresh self-view.
    final res = await dio.get<Map<String, dynamic>>('/api/me');
    final updated =
        SelfView.fromJson(res.data!['user'] as Map<String, dynamic>);
    _ref.read(authStateProvider.notifier).updateSelfView(updated);
  }
}

final verificationsApiProvider =
    Provider<VerificationsApi>((ref) => VerificationsApi(ref));
