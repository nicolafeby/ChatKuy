import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class FileConverterHelper {
  FileConverterHelper._();

  /// Convert File to Base64 string
  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    final compressed = gzip.encode(bytes);
    return base64Encode(compressed);
    // final Uint8List bytes = await file.readAsBytes();
    // return base64Encode(bytes);
  }

  static Future<List<int>> base64ToFile(String base64) async {
    final compressed = base64Decode(base64);
    return gzip.decode(compressed);
  }

  /// Convert XFile to Base64 string
  static Future<String> xFileToBase64(XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Decode Base64 back to bytes (for preview)
  static Uint8List base64ToBytes(String base64) {
    return base64Decode(base64);
  }
}
