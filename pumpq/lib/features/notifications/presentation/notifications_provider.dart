import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) => AppNotificationItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class NotificationStorage {
  static const key = 'user_notifications_history';

  static Future<void> save({required String title, required String body}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(key) ?? [];
      final item = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'receivedAt': DateTime.now().toIso8601String(),
      };
      raw.insert(0, jsonEncode(item));
      if (raw.length > 50) raw.removeRange(50, raw.length);
      await prefs.setStringList(key, raw);
    } catch (_) {}
  }
}

class NotificationsNotifier extends Notifier<List<AppNotificationItem>> {
  @override
  List<AppNotificationItem> build() {
    load();
    return const [];
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(NotificationStorage.key) ?? [];
      final items = raw
          .map((e) {
            try {
              return AppNotificationItem.fromJson(jsonDecode(e) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<AppNotificationItem>()
          .toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      state = items;
    } catch (_) {}
  }

  Future<void> removeNotification(String id) async {
    state = state.where((item) => item.id != id).toList();
    _persist();
  }

  Future<void> clearAll() async {
    state = const [];
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = state.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(NotificationStorage.key, raw);
    } catch (_) {}
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotificationItem>>(NotificationsNotifier.new);
