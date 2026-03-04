import 'dart:io';

import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class LocalImageModel {
  final String localImagePath;
  final String downloadUrl;

  const LocalImageModel({required this.localImagePath, required this.downloadUrl});
}

Future<String> saveImageToLocal({required File imageFile, required String roomId}) async {
  final directory = await getApplicationDocumentsDirectory();

  final chatDir = Directory('${directory.path}/${StorageCollection.chatImages}');
  if (!await chatDir.exists()) {
    await chatDir.create(recursive: true);
  }

  final fileName =
      '${AppStrings.appName}_${roomId}_${DateTime.now().millisecondsSinceEpoch}${extension(imageFile.path)}';

  final newPath = '${chatDir.path}/$fileName';

  final newFile = await imageFile.copy(newPath);

  return newFile.path;
}
