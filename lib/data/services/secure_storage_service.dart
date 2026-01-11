import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService implements SecureStorageRepository {
  static const _storage = FlutterSecureStorage();

  static const _keyIsLogin = 'is_login';
  static const _keyUserID = 'user_id';

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
    await _storage.deleteAll();
  }
}
