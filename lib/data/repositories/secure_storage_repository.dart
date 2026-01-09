abstract class SecureStorageRepository {
  Future<void> setIsLogin(bool value);
  Future<bool> getIsLogin();

  Future<void> setAccessToken(String token);
  Future<String?> getAccessToken();

  Future<void> clear();
}
