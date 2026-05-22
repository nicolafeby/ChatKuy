import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_compress/video_compress.dart';

Future<File> compressChatVideo({
  required File videoFile,
  VideoQuality quality = VideoQuality.MediumQuality,
  bool deleteOrigin = false,
  void Function(int progress)? onProgress,
}) async {
  final originalSize = await videoFile.length();

  try {
    final subscription = VideoCompress.compressProgress$.subscribe((progress) {
      onProgress?.call(progress.round().clamp(0, 100));
    });

    MediaInfo? info;

    try {
      info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: deleteOrigin,
        includeAudio: true,
      );
    } finally {
      subscription.unsubscribe();
    }

    final compressedPath = info?.path;
    if (compressedPath == null) {
      debugPrint('[ChatVideoCompress] Compression returned null.');
      return videoFile;
    }

    final result = File(compressedPath);
    final compressedSize = await result.length();
    final savedPercent =
        ((1 - (compressedSize / originalSize)) * 100).clamp(0, 100);

    debugPrint(
      '[ChatVideoCompress] original=${_formatBytes(originalSize)}, '
      'compressed=${_formatBytes(compressedSize)}, '
      'saved=${savedPercent.toStringAsFixed(1)}%',
    );

    return compressedSize < originalSize ? result : videoFile;
  } on MissingPluginException {
    debugPrint('[ChatVideoCompress] Missing plugin, using original video.');
    return videoFile;
  } catch (e) {
    debugPrint('[ChatVideoCompress] Failed to compress video: $e');
    return videoFile;
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';

  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

  final mb = kb / 1024;
  return '${mb.toStringAsFixed(2)} MB';
}
