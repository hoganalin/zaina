import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';

class FcmService {
  FcmService._();

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;

  /// Best-effort registration — silently no-ops on web / unsupported platforms.
  Future<void> register() async {
    if (kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) await _sendToken(token);

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen(_sendToken);

      _foregroundSub?.cancel();
      _foregroundSub =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    } catch (e) {
      debugPrint('[fcm] register failed: $e');
    }
  }

  Future<void> unregister() async {
    _foregroundSub?.cancel();
    _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _tokenRefreshSub = null;
    try {
      await dio.patch('/api/me/push-token', data: {'fcmToken': null});
    } catch (_) {/* best effort */}
  }

  Future<void> _sendToken(String token) async {
    try {
      await dio.patch('/api/me/push-token', data: {'fcmToken': token});
    } catch (e) {
      debugPrint('[fcm] token POST failed: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      '[fcm] foreground message: ${message.notification?.title} — ${message.notification?.body}',
    );
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final svc = FcmService._();
  ref.onDispose(svc.unregister);
  return svc;
});
