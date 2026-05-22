import 'dart:async';
import 'dart:ui';

import 'package:chatkuy/app_context.dart';
import 'package:chatkuy/data/repositories/local_notification_repository.dart';
import 'package:chatkuy/data/repositories/notification_repository.dart';
import 'package:chatkuy/data/services/presence_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'di/injection.dart';

Future<void> main() async {
  var isCrashlyticsReady = false;

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      isCrashlyticsReady = true;

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await setupDI();
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
    },
    (error, stack) {
      if (isCrashlyticsReady) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}
