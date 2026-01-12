import 'package:chatkuy/app_context.dart';
import 'package:chatkuy/data/repositories/local_notification_repository.dart';
import 'package:chatkuy/data/repositories/notification_repository.dart';
import 'package:chatkuy/data/services/local_notification_service.dart';
import 'package:chatkuy/data/services/presence_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  setupDI();
  await getIt<LocalNotificationRepository>().init();
  await AppContext.init();
  await getIt<NotificationRepository>().init();
  getIt<PresenceService>().init();

  FirebaseMessaging.onMessage.listen((message) {
    getIt<LocalNotificationRepository>().show(message);
  });

  runApp(const MyApp());
}
