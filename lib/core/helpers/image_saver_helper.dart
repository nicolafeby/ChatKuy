
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

Future<String> saveImageToLocal(File imageFile) async {
  final directory = await getApplicationDocumentsDirectory();

  final chatDir = Directory('${directory.path}/chat_images');
  if (!await chatDir.exists()) {
    await chatDir.create(recursive: true);
  }

  final fileName = '${DateTime.now().millisecondsSinceEpoch}${extension(imageFile.path)}';

  final newPath = '${chatDir.path}/$fileName';

  final newFile = await imageFile.copy(newPath);

  return newFile.path;
}
