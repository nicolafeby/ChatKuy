import 'package:chatkuy/app_context.dart';
import 'package:chatkuy/data/repositories/local_notification_repository.dart';
import 'package:chatkuy/data/repositories/notification_repository.dart';
import 'package:chatkuy/data/services/presence_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupDI();
  await getIt<LocalNotificationRepository>().init();
  await AppContext.init();
  await getIt<NotificationRepository>().init();
  getIt<PresenceService>().init();

  FirebaseMessaging.onMessage.listen((message) {
    getIt<LocalNotificationRepository>().show(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    getIt<NotificationRepository>().handleMessage(message);
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    getIt<NotificationRepository>().handleMessage(initialMessage);
  }

  runApp(const MyApp());
}
