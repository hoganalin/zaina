import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_post.dart';
import '../models/self_view.dart';
import '../screens/sign_in/auth_providers.dart';
import 'dio_client.dart';

class PublicUser {
  PublicUser({
    required this.id,
    required this.nickname,
    this.gender,
    this.country,
    this.city,
    this.avatarUrl,
    this.bio,
    required this.isVerified,
    required this.postCount,
  });

  final String id;
  final String nickname;
  final Gender? gender;
  final String? country;
  final String? city;
  final String? avatarUrl;
  final String? bio;
  final bool isVerified;
  final int postCount;

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    Gender? parseGender(dynamic v) => switch (v) {
          'male' => Gender.male,
          'female' => Gender.female,
          'non_binary' => Gender.nonBinary,
          _ => null,
        };
    return PublicUser(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      gender: parseGender(json['gender']),
      country: json['country'] as String?,
      city: json['city'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      postCount: json['postCount'] as int? ?? 0,
    );
  }
}

final publicUserProvider =
    FutureProvider.family<PublicUser, String>((ref, userId) async {
  final res = await dio.get<Map<String, dynamic>>('/api/users/$userId');
  return PublicUser.fromJson(res.data!['user'] as Map<String, dynamic>);
});

final userPostsProvider =
    FutureProvider.family<List<FeedPost>, String>((ref, userId) async {
  final res = await dio.get<Map<String, dynamic>>('/api/users/$userId/posts');
  final list = res.data!['posts'] as List<dynamic>;
  return list
      .map((j) => FeedPost.fromJson(j as Map<String, dynamic>))
      .toList();
});

class UsersApi {
  UsersApi(this._ref);
  final Ref _ref;

  Future<SelfView> patchMe({
    String? nickname,
    Gender? gender,
    String? country,
    String? city,
    String? bio,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{
      'nickname': ?nickname,
      'gender': ?(gender == null ? null : _genderToJson(gender)),
      'country': ?country,
      'city': ?city,
      'bio': ?bio,
      'avatarUrl': ?avatarUrl,
    };
    final res = await dio.patch<Map<String, dynamic>>('/api/me', data: body);
    final updated =
        SelfView.fromJson(res.data!['user'] as Map<String, dynamic>);
    _ref.read(authStateProvider.notifier).updateSelfView(updated);
    _ref.invalidate(publicUserProvider(updated.id));
    return updated;
  }
}

extension BlockApi on UsersApi {
  Future<void> block(String userId) async {
    await dio.post('/api/users/$userId/block');
  }

  Future<void> unblock(String userId) async {
    await dio.delete('/api/users/$userId/block');
  }
}

final usersApiProvider = Provider<UsersApi>((ref) => UsersApi(ref));

String _genderToJson(Gender g) => switch (g) {
      Gender.male => 'male',
      Gender.female => 'female',
      Gender.nonBinary => 'non_binary',
    };
