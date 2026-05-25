import 'dart:convert';
import 'dart:math';

import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService implements SecureStorageRepository {
  static const _storage = FlutterSecureStorage();

  static const _keyIsLogin = 'is_login';
  static const _keyUserID = 'user_id';
  static const _keyFcmToken = 'fcmToken';
  static const _keyThemeMode = 'theme_mode';
  static const _hiveEncryptionKeyName = 'hive_encryption_key_v1';

  @override
  Future<void> setIsLogin(bool value) async {
    await _storage.write(
      key: _keyIsLogin,
      value: value.toString(),
    );
  }

  @override
  Future<bool> getIsLogin() async {
    final value = await _storage.read(key: _keyIsLogin);
    return value == true.toString();
  }

  @override
  Future<void> setUserId(String token) async {
    await _storage.write(
      key: _keyUserID,
      value: token,
    );
  }

  @override
  Future<String?> getUserId() async {
    return _storage.read(key: _keyUserID);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _keyIsLogin),
      _storage.delete(key: _keyUserID),
      _storage.delete(key: _keyFcmToken),
    ]);
  }

  @override
  Future<String?> getFcmToken() async {
    return _storage.read(key: _keyFcmToken);
  }

  @override
  Future<void> setFcmToken(String token) async {
    await _storage.write(
      key: _keyFcmToken,
      value: token,
    );
  }

  @override
  Future<String?> getThemeModeName() async {
    return _storage.read(key: _keyThemeMode);
  }

  @override
  Future<void> setThemeModeName(String value) async {
    await _storage.write(
      key: _keyThemeMode,
      value: value,
    );
  }

  @override
  Future<List<int>> getHiveEncryptionKey() async {
    final storedKey = await _storage.read(key: _hiveEncryptionKeyName);
    if (storedKey != null) {
      return base64Url.decode(storedKey);
    }

    final key = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    await _storage.write(
      key: _hiveEncryptionKeyName,
      value: base64UrlEncode(key),
    );

    return key;
  }
}
