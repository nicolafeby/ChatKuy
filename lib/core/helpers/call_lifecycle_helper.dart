import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:flutter/services.dart';

class CallLifecycleHelper {
  const CallLifecycleHelper._();

  static const MethodChannel _channel = MethodChannel('com.ncladr.chatkuy/call_lifecycle');

  static Future<void> moveTaskToBackOrCloseApp() async {
    try {
      await _channel.invokeMethod<void>('moveTaskToBack');
    } on PlatformException catch (e, stackTrace) {
      await AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Move app task to back failed with PlatformException',
        context: {'code': e.code},
      );
      await SystemNavigator.pop();
    } on MissingPluginException catch (e, stackTrace) {
      await AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Move app task to back missing native plugin',
      );
      await SystemNavigator.pop();
    } catch (e, stackTrace) {
      await AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Move app task to back failed with unknown error',
      );
      await SystemNavigator.pop();
    }
  }
}
