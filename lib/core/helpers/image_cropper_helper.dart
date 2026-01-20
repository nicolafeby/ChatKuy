import 'dart:io';

import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

class ImageCropperHelper {
  ImageCropperHelper._();

  /// Crop image with default UI settings
  static Future<File?> cropImage({
    required File imageFile,
    CropAspectRatioPreset? aspectRatioPreset,
    bool lockAspectRatio = false,
  }) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: aspectRatioPreset != null ? _mapAspectRatio(aspectRatioPreset) : null,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: lockAspectRatio,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: lockAspectRatio,
        ),
      ],
    );

    if (croppedFile == null) return null;

    return File(croppedFile.path);
  }

  static CropAspectRatio _mapAspectRatio(
    CropAspectRatioPreset preset,
  ) {
    switch (preset) {
      case CropAspectRatioPreset.square:
        return const CropAspectRatio(ratioX: 1, ratioY: 1);
      case CropAspectRatioPreset.ratio16x9:
        return const CropAspectRatio(ratioX: 16, ratioY: 9);
      case CropAspectRatioPreset.ratio4x3:
        return const CropAspectRatio(ratioX: 4, ratioY: 3);
      default:
        return const CropAspectRatio(ratioX: 1, ratioY: 1);
    }
  }
}
