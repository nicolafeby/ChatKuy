import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart' as image_picker;

class FileConverterHelper {
  FileConverterHelper._();

  /// Convert File to Base64 string
  static Future<String> fileToBase64(File file) async {
    final bytes = await _compressedProfileImageBytes(file);
    final compressed = gzip.encode(bytes);
    return base64Encode(compressed);
  }

  static Future<Uint8List> _compressedProfileImageBytes(File file) async {
    const maxBase64Length = 700 * 1024;
    const widths = [512, 384, 320];
    const qualities = [74, 62, 50, 38];

    Uint8List? bestBytes;

    for (final width in widths) {
      for (final quality in qualities) {
        final bytes = await FlutterImageCompress.compressWithFile(
          file.path,
          minWidth: width,
          minHeight: width,
          quality: quality,
          format: CompressFormat.jpeg,
          keepExif: false,
        );

        if (bytes == null || bytes.isEmpty) continue;
        bestBytes = bytes;

        final encodedLength = base64Encode(gzip.encode(bytes)).length;
        if (encodedLength <= maxBase64Length) {
          return bytes;
        }
      }
    }

    if (bestBytes != null) return bestBytes;
    return file.readAsBytes();
  }

  static Future<List<int>> base64ToFile(String base64) async {
    final compressed = base64Decode(base64);
    return gzip.decode(compressed);
  }

  /// Convert XFile to Base64 string
  static Future<String> xFileToBase64(image_picker.XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Decode Base64 back to bytes (for preview)
  static Uint8List base64ToBytes(String base64) {
    return base64Decode(base64);
  }
}
