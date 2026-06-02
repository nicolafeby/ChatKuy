import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/stores/session/session_store.dart';

class AppContext {
  static late SecureStorageRepository storage;
  static late SessionStore sessionStore;

  static Future<void> init(SecureStorageRepository storageRepository) async {
    storage = storageRepository;
    sessionStore = SessionStore(storage);
    await sessionStore.init();
  }
}
