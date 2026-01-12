abstract class SecureStorageRepository {
  Future<void> setIsLogin(bool value);
  Future<bool> getIsLogin();

  Future<void> setUserId(String token);
  Future<String?> getUserId();

  Future<void> setFcmToken(String token);
  Future<String?> getFcmToken();

  Future<void> clear();
}
