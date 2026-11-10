import 'dart:async';

import 'package:chatkuy/app.dart';
import 'package:chatkuy/core/bootstrap/app_bootstrapper.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  var isCrashlyticsReady = false;

  await runZonedGuarded(
    () async {
      final initialCallArgument = await AppBootstrapper.initialize(
        onCrashlyticsReady: () => isCrashlyticsReady = true,
      );

      runApp(MyApp(initialCallArgument: initialCallArgument));
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => AppBootstrapper.afterFirstFrame(initialCallArgument),
      );
    },
    (error, stack) {
      if (!isCrashlyticsReady) return;
      AppErrorLogger.recordError(
        error,
        stack,
        reason: 'Unhandled zoned error',
        fatal: true,
      );
    },
  );
}
