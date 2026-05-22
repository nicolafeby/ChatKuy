abstract class HiveEncryptionRepository {
  Future<void> openEncryptedBoxes();
  Future<void> clearSensitiveData();
}
