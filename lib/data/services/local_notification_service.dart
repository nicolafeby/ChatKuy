import 'package:chatkuy/data/repositories/local_notification_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService implements LocalNotificationRepository {
  static final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      'chat_notification',
      'Chat Notification',
      description: 'Notification for incoming chat messages',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @override
  void show(RemoteMessage message) {
    final title = message.notification?.title ?? 'Pesan baru';
    final body = message.notification?.body ?? message.data['text'] ?? '';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_notification',
        'Chat Notification',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
