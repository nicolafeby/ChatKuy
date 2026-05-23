import 'package:firebase_messaging/firebase_messaging.dart';

abstract class NotificationRepository {
  Future<void> init();
  Future<void> clearCurrentUserToken();
  void handleMessage(RemoteMessage message);
}
