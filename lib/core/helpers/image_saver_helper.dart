import 'dart:io';

import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

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

  final fileName = imageNameFormat(roomId, imageFile);

  final newPath = '${chatDir.path}/$fileName';

  final newFile = await imageFile.copy(newPath);

  return newFile.path;
}

Future<String> getOrDownloadImage({required String imageUrl}) async {
  final directory = await getApplicationDocumentsDirectory();

  final chatDir = Directory('${directory.path}/${StorageCollection.chatImages}');
  if (!await chatDir.exists()) {
    await chatDir.create(recursive: true);
  }

  final fileName = _extractFileName(imageUrl);
  final localPath = '${chatDir.path}/$fileName';

  final file = File(localPath);

  /// cek apakah sudah ada di local
  if (await file.exists()) {
    return file.path;
  }

  /// download jika belum ada
  final response = await http.get(Uri.parse(imageUrl));

  if (response.statusCode == 200) {
    await file.writeAsBytes(response.bodyBytes);
  }

  return file.path;
}

String _extractFileName(String url) {
  final uri = Uri.parse(url);

  final decoded = Uri.decodeComponent(uri.path);

  return decoded.split('/').last;
}

String imageNameFormat(String roomId, File file) =>
    '${AppStrings.appName}_${roomId}_${DateTime.now().millisecondsSinceEpoch}${extension(file.path)}';
