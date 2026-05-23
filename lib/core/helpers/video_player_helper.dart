import 'dart:io';

import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerHelper {
  const VideoPlayerHelper._();

  static Future<VideoPlayerController?> initializeFile({
    required File file,
    required String reason,
    Map<String, Object?> context = const {},
  }) {
    return initializeController(
      controller: VideoPlayerController.file(file),
      reason: reason,
      context: {
        ...context,
        'source': 'file',
        'path_hash': file.path.hashCode,
      },
    );
  }

  static Future<VideoPlayerController?> initializeNetwork({
    required Uri uri,
    required String reason,
    Map<String, Object?> context = const {},
  }) {
    return initializeController(
      controller: VideoPlayerController.networkUrl(uri),
      reason: reason,
      context: {
        ...context,
        'source': 'network',
        'host': uri.host,
      },
    );
  }

  static Future<VideoPlayerController?> initializeController({
    required VideoPlayerController controller,
    required String reason,
    Map<String, Object?> context = const {},
  }) async {
    try {
      await controller.initialize();
      return controller;
    } catch (e, stackTrace) {
      await AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: reason,
        context: context,
      );
      await controller.dispose();
      return null;
    }
  }
}
