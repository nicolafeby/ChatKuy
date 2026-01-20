import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

extension Base64GzipToBytes on String {
  Uint8List base64GzipToBytes() {
    final compressed = base64Decode(this);
    return Uint8List.fromList(gzip.decode(compressed));
  }
}
