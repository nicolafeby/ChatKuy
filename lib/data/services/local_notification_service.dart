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
  }

  @override
  void show(RemoteMessage message) {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_notification',
        'Chat Notification',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    _plugin.show(message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,);
  }
}
