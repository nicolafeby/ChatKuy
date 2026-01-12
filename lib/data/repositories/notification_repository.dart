import 'package:firebase_messaging/firebase_messaging.dart';

abstract class NotificationRepository {
  Future<void> init();
  void handleMessage(RemoteMessage message);
}
