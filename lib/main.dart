import 'dart:async';
import 'dart:ui';

import 'package:chatkuy/app_context.dart';
import 'package:chatkuy/data/repositories/local_notification_repository.dart';
import 'package:chatkuy/data/repositories/notification_repository.dart';
import 'package:chatkuy/data/services/local_notification_service.dart';
import 'package:chatkuy/data/services/presence_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'di/injection.dart';

class _CallKitLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      LocalNotificationService.processPendingLaunchNotification();
    });
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (message.data['type'] == 'voice_call') {
    await LocalNotificationService.showFromBackground(message);
  }
}

Future<void> main() async {
  var isCrashlyticsReady = false;

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
      WidgetsBinding.instance.addObserver(_CallKitLifecycleObserver());

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

      final initialVoiceCallArgument = await LocalNotificationService.takeInitialAcceptedCallArgument();

      runApp(MyApp(initialVoiceCallArgument: initialVoiceCallArgument));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LocalNotificationService.processPendingLaunchNotification();
      });
      Future.delayed(const Duration(seconds: 1), () {
        LocalNotificationService.processPendingLaunchNotification();
      });
    },
    (error, stack) {
      if (isCrashlyticsReady) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}
