import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:mobx/mobx.dart';

part 'session_store.g.dart';

class SessionStore = _SessionStore with _$SessionStore;

abstract class _SessionStore with Store {
  final SecureStorageRepository storage;

  _SessionStore(this.storage);

  @observable
  bool isLoggedIn = false;

  @observable
  bool isReady = false;

  @action
  Future<void> init() async {
    isLoggedIn = await storage.getIsLogin();
    isReady = true;
  }

  @action
  Future<void> setLoggedIn(bool value) async {
    await storage.setIsLogin(value);
    isLoggedIn = value;
  }

  @action
  Future<void> logout() async {
    await storage.clear();
    isLoggedIn = false;
  }
}
