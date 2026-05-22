import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File> compressChatImage({
  required File imageFile,
  int quality = 72,
  int minWidth = 1280,
  int minHeight = 1280,
}) async {
  final originalSize = await imageFile.length();

  final tempDir = await getTemporaryDirectory();
  final fileName =
      '${p.basenameWithoutExtension(imageFile.path)}_compressed.jpg';
  final targetPath = p.join(tempDir.path, fileName);

  dynamic compressedFile;

  try {
    compressedFile = await FlutterImageCompress.compressAndGetFile(
      imageFile.path,
      targetPath,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
  } on MissingPluginException {
    debugPrint(
      '[ChatImageCompress] Missing plugin, using original image. '
      'original=${_formatBytes(originalSize)}',
    );
    return imageFile;
  }

  if (compressedFile == null) {
    debugPrint(
      '[ChatImageCompress] Compression returned null, using original image. '
      'original=${_formatBytes(originalSize)}',
    );
    return imageFile;
  }

  final result = File(compressedFile.path);
  final compressedSize = await result.length();
  final savedPercent =
      ((1 - (compressedSize / originalSize)) * 100).clamp(0, 100);

  debugPrint(
    '[ChatImageCompress] original=${_formatBytes(originalSize)}, '
    'compressed=${_formatBytes(compressedSize)}, '
    'saved=${savedPercent.toStringAsFixed(1)}%',
  );

  return compressedSize < originalSize ? result : imageFile;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';

  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

  final mb = kb / 1024;
  return '${mb.toStringAsFixed(2)} MB';
}
