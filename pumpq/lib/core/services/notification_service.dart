import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Notification permission denied');
      return;
    }

    final token = await _messaging.getToken();
    debugPrint('FCM token: $token');
    // TODO: send this token to the backend so it can target this device later.

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      // TODO: show an in-app banner or local notification here once
      // flutter_local_notifications is re-enabled.
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped: ${message.notification?.title}');
      // TODO: navigate to a relevant screen based on message.data.
    });
  }

  Future<String?> getToken() => _messaging.getToken();
}