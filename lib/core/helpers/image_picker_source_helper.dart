import 'dart:io';

import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:image_picker/image_picker.dart';

enum PickImageSource {
  camera,
  gallery,
}

class ImagePickerHelper {
  ImagePickerHelper._();

  static final ImagePicker _picker = ImagePicker();

  /// Pick image from camera or gallery
  static Future<File?> pickImage({
    required PickImageSource source,
    int imageQuality = 80,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source == PickImageSource.camera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Pick image failed',
        context: {'source': source.name},
      );
      return null;
    }
  }

  static Future<File?> pickVideo({
    required PickImageSource source,
    Duration? maxDuration,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source == PickImageSource.camera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: maxDuration,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Pick video failed',
        context: {'source': source.name},
      );
      return null;
    }
  }
}
