import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/data/services/secure_storage_service.dart';
import 'package:chatkuy/stores/session/session_store.dart';

class AppContext {
  static late SecureStorageRepository storage;
  static late SessionStore sessionStore;

  static Future<void> init() async {
    storage = SecureStorageService();
    sessionStore = SessionStore(storage);
    await sessionStore.init();
  }
}
