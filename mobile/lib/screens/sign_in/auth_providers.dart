import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../api/dio_client.dart';
import '../../api/fcm_service.dart';
import '../../models/self_view.dart';

class AuthNotifier extends AsyncNotifier<SelfView?> {
  @override
  Future<SelfView?> build() async {
    if (FirebaseAuth.instance.currentUser == null) return null;
    return _fetchSelfView();
  }

  Future<SelfView?> _fetchSelfView() async {
    final res = await dio.post<Map<String, dynamic>>('/api/auth/session');
    final data = res.data!;
    final view = SelfView.fromJson(data['user'] as Map<String, dynamic>);
    // Best-effort FCM registration; never blocks sign-in.
    unawaited(ref.read(fcmServiceProvider).register());
    return view;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final account = await GoogleSignIn().signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      final cred = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(cred);
      return _fetchSelfView();
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final cred = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      await FirebaseAuth.instance.signInWithCredential(cred);
      return _fetchSelfView();
    });
  }

  void updateSelfView(SelfView updated) {
    state = AsyncData(updated);
  }

  Future<void> submitOnboarding({
    required String nickname,
    Gender? gender,
    String? country,
    String? city,
    required Set<String> interestIds,
    required Set<String> channelIds,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await dio.patch<Map<String, dynamic>>(
        '/api/me/onboarding',
        data: {
          'nickname': nickname,
          if (gender != null) 'gender': _genderToJson(gender),
          if (country != null && country.isNotEmpty) 'country': country,
          if (city != null && city.isNotEmpty) 'city': city,
          'interestIds': interestIds.toList(),
          'channelIds': channelIds.toList(),
        },
      );
      return SelfView.fromJson(res.data!['user'] as Map<String, dynamic>);
    });
  }

  Future<void> signOut() async {
    await ref.read(fcmServiceProvider).unregister();
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Apple sign-out has no SDK equivalent; clearing Firebase session is enough.
    }
    state = const AsyncData(null);
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, SelfView?>(
  AuthNotifier.new,
);

String _genderToJson(Gender g) => switch (g) {
      Gender.male => 'male',
      Gender.female => 'female',
      Gender.nonBinary => 'non_binary',
    };

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}

final authRouterRefreshProvider = Provider<Listenable>((ref) {
  return _RouterRefreshNotifier(ref);
});
