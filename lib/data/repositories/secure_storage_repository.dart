abstract class SecureStorageRepository {
  Future<void> setIsLogin(bool value);
  Future<bool> getIsLogin();

  Future<void> setUserId(String token);
  Future<String?> getUserId();

  Future<void> setFcmToken(String token);
  Future<String?> getFcmToken();

  Future<void> setThemeModeName(String value);
  Future<String?> getThemeModeName();

  Future<void> setLanguageCode(String value);
  Future<String?> getLanguageCode();

  Future<List<int>> getHiveEncryptionKey();

  Future<void> clear();
}
