import 'dart:async';
import 'dart:ui';

import 'package:chatkuy/app_context.dart';
import 'package:chatkuy/core/config/language/language_controller.dart';
import 'package:chatkuy/core/config/theme/theme_controller.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/navigation/initial_route_argument.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/repositories/local_notification_repository.dart';
import 'package:chatkuy/data/repositories/notification_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/data/services/app_update_service.dart';
import 'package:chatkuy/data/services/local_notification_service.dart';
import 'package:chatkuy/data/services/presence_service.dart';
import 'package:chatkuy/ui/update/update_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'di/injection.dart';

const _enableUpdateCheckInDebug = bool.fromEnvironment(
  'ENABLE_UPDATE_CHECK_IN_DEBUG',
);

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

  try {
    if (message.data['type'] == 'chat') {
      await LocalNotificationService.markChatMessageDeliveredFromPayload(
        message.data,
      );
    } else if (message.data['type'] == 'voice_call' ||
        message.data['type'] == 'video_call' ||
        message.data['type'] == 'voice_call_ended' ||
        message.data['type'] == 'video_call_ended') {
      await LocalNotificationService.showFromBackground(message);
    }
  } catch (error, stackTrace) {
    await AppErrorLogger.recordError(
      error,
      stackTrace,
      reason: 'Failed to process background Firebase message',
      context: {
        'message_id': message.messageId,
        'message_type': message.data['type'],
      },
    );
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
      await AppErrorLogger.setUserId(FirebaseAuth.instance.currentUser?.uid);

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        AppErrorLogger.recordError(
          error,
          stack,
          reason: 'Unhandled platform dispatcher error',
          fatal: true,
        );
        return true;
      };

      await setupDI();
      await getIt<ThemeController>().init();
      await getIt<LanguageController>().init();
      await getIt<LocalNotificationRepository>().init();
      await AppContext.init(getIt<SecureStorageRepository>());
      WidgetsBinding.instance.addObserver(_CallKitLifecycleObserver());

      FirebaseMessaging.onMessage.listen(
        (message) async {
          await getIt<LocalNotificationRepository>().show(message);
        },
        onError: (error, stackTrace) {
          AppErrorLogger.recordError(
            error,
            stackTrace,
            reason: 'Firebase foreground message stream failed',
          );
        },
      );

      final initialCallArgument = await LocalNotificationService.takeInitialAcceptedCallArgument();

      runApp(MyApp(
        initialCallArgument: initialCallArgument,
      ));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDeferredServices();
        LocalNotificationService.processPendingLaunchNotification();
        if (initialCallArgument == null) {
          unawaited(_checkForUpdateAfterFirstFrame());
        }
      });
    },
    (error, stack) {
      if (isCrashlyticsReady) {
        AppErrorLogger.recordError(
          error,
          stack,
          reason: 'Unhandled zoned error',
          fatal: true,
        );
      }
    },
  );
}

void _startDeferredServices() {
  getIt<PresenceService>().init();
  unawaited(getIt<NotificationRepository>().init());
}

Future<void> _checkForUpdateAfterFirstFrame() async {
  if (kDebugMode && !_enableUpdateCheckInDebug) return;

  final updateInfo = await getIt<AppUpdateService>().checkForUpdate();
  if (kDebugMode) {
    debugPrint(
      'App update check: '
      'current=${updateInfo.currentVersion}+${updateInfo.currentBuildNumberText}, '
      'minimum=${updateInfo.minimumRequiredVersion}+${updateInfo.minimumRequiredBuildNumberText}, '
      'recommended=${updateInfo.recommendedVersion}+${updateInfo.recommendedBuildNumberText}, '
      'type=${updateInfo.type.name}',
    );
  }

  if (!updateInfo.shouldShowUpdate) return;
  if (Get.currentRoute == AppRouteName.APP_UPDATE_SCREEN) return;
  if (Get.currentRoute == AppRouteName.CALL_SCREEN) return;

  final nextRouteName = Get.currentRoute.isEmpty ? AppRouteName.BASE_SCREEN : Get.currentRoute;
  InitialRouteArgument.appUpdate = AppUpdateScreenArgument(
    updateInfo: updateInfo,
    nextRouteName: nextRouteName,
  );
  Get.toNamed(AppRouteName.APP_UPDATE_SCREEN);
}
