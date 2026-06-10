import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:chatkuy/data/repositories/message_encryption_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class MessageEncryptionService implements MessageEncryptionRepository {
  static const _version = 1;
  static const _algorithm = 'aes-256-ctr-hmac-sha256';
  static const _purpose = 'chatkuy-message-content-v1';

  final Random _random = Random.secure();

  @override
  Map<String, dynamic> encryptPayload({
    required String roomId,
    required List<String> participants,
    required Map<String, dynamic> payload,
  }) {
    final plaintext = utf8.encode(jsonEncode(payload));
    final iv = _randomBytes(16);
    final keys = _keysFor(roomId: roomId, participants: participants);
    final encrypted = _crypt(
      input: Uint8List.fromList(plaintext),
      key: keys.encryptionKey,
      iv: iv,
    );
    final mac = Hmac(sha256, keys.macKey).convert([...iv, ...encrypted]).bytes;

    return {
      'v': _version,
      'alg': _algorithm,
      'iv': base64UrlEncode(iv),
      'data': base64UrlEncode(encrypted),
      'mac': base64UrlEncode(mac),
    };
  }

  @override
  Map<String, dynamic>? decryptPayload({
    required String roomId,
    required List<String> participants,
    required Map<String, dynamic>? encryptedPayload,
  }) {
    if (encryptedPayload == null ||
        encryptedPayload['v'] != _version ||
        encryptedPayload['alg'] != _algorithm) {
      return null;
    }

    final iv = _decode(encryptedPayload['iv']);
    final encrypted = _decode(encryptedPayload['data']);
    final expectedMac = _decode(encryptedPayload['mac']);
    if (iv == null || encrypted == null || expectedMac == null) return null;

    final keys = _keysFor(roomId: roomId, participants: participants);
    final actualMac =
        Hmac(sha256, keys.macKey).convert([...iv, ...encrypted]).bytes;
    if (!_constantTimeEquals(expectedMac, actualMac)) return null;

    final decrypted = _crypt(
      input: encrypted,
      key: keys.encryptionKey,
      iv: iv,
    );
    final decoded = jsonDecode(utf8.decode(decrypted));
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  Uint8List _crypt({
    required Uint8List input,
    required Uint8List key,
    required Uint8List iv,
  }) {
    final cipher = StreamCipher('AES/SIC')
      ..init(true, ParametersWithIV(KeyParameter(key), iv));
    return cipher.process(input);
  }

  _MessageKeys _keysFor({
    required String roomId,
    required List<String> participants,
  }) {
    final sortedParticipants = [...participants]..sort();
    final seed = '$_purpose:$roomId:${sortedParticipants.join(':')}';
    return _MessageKeys(
      encryptionKey: Uint8List.fromList(
        sha256.convert(utf8.encode('$seed:encryption')).bytes,
      ),
      macKey: Uint8List.fromList(
        sha256.convert(utf8.encode('$seed:authentication')).bytes,
      ),
    );
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }

  Uint8List? _decode(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return Uint8List.fromList(base64Url.decode(value));
    } catch (_) {
      return null;
    }
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

class _MessageKeys {
  const _MessageKeys({
    required this.encryptionKey,
    required this.macKey,
  });

  final Uint8List encryptionKey;
  final Uint8List macKey;
}
