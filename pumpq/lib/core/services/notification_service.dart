import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:pumpq/core/services/top_notification_banner.dart';
import 'package:pumpq/features/notifications/presentation/notifications_provider.dart';

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
    // Token is synced to the backend via auth_provider._syncFcmToken() on login.

    // Show an in-app banner when a notification arrives while the app is open.
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      debugPrint('Foreground message: $title');
      if (title.isNotEmpty || body.isNotEmpty) {
        NotificationStorage.save(title: title, body: body);
        TopNotificationBanner.show(title: title, body: body);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      debugPrint('Notification tapped: $title');
      if (title.isNotEmpty || body.isNotEmpty) {
        NotificationStorage.save(title: title, body: body);
      }
    });
  }

  Future<String?> getToken() => _messaging.getToken();
}