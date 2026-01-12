import 'package:firebase_messaging/firebase_messaging.dart';

abstract class LocalNotificationRepository {
  Future<void> init();
  void show(RemoteMessage message);
}
