import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService implements SecureStorageRepository {
  static const _storage = FlutterSecureStorage();

  static const _keyIsLogin = 'is_login';
  static const _keyAccessToken = 'access_token';

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
    return value == 'true';
  }

  @override
  Future<void> setAccessToken(String token) async {
    await _storage.write(
      key: _keyAccessToken,
      value: token,
    );
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
