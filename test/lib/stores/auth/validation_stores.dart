import 'package:chatkuy/data/models/edit_profile_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/stores/auth/login/login_store.dart';
import 'package:chatkuy/stores/auth/register/register_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> authValidationStoresTest() async {
  group('LoginStore validation', () {
    test('validates username and exposes isValid', () {
      final store = LoginStore(
        service: _FakeAuthRepository(),
        storageService: _FakeSecureStorageRepository(),
        presenceService: _FakePresenceRepository(),
      );

      store.validateUsername('');
      expect(store.error.username, 'Username tidak boleh kosong');
      expect(store.isValid, isFalse);

      store.validateUsername('abc');
      expect(store.error.username, 'Username minimal 5 huruf');

      store.validateUsername('abcdef');
      store.password = 'secret';

      expect(store.error.username, isNull);
      expect(store.isValid, isTrue);
    });
  });

  group('RegisterStore validation', () {
    test('validates name boundaries and allowed characters', () {
      final store = RegisterStore(
        service: _FakeAuthRepository(),
        storageService: _FakeSecureStorageRepository(),
      );

      store.validateName('');
      expect(store.error.name, 'Nama tidak boleh kosong');

      store.validateName('Al');
      expect(store.error.name, 'Nama minimal 3 karakter');

      store.validateName('A1ya');
      expect(store.error.name, 'Nama hanya boleh berisi huruf dan spasi');

      store.validateName('Alya Putri');
      expect(store.error.name, isNull);
    });

    test('validates email format', () {
      final store = RegisterStore(
        service: _FakeAuthRepository(),
        storageService: _FakeSecureStorageRepository(),
      );

      store.validateEmail('');
      expect(store.error.email, 'Email tidak boleh kosong');

      store.validateEmail('not-an-email');
      expect(store.error.email, 'Format email tidak valid');

      store.validateEmail('alya@example.com');
      expect(store.error.email, isNull);
    });

    test('checks username availability for valid username', () async {
      final authRepository = _FakeAuthRepository(usernameAvailable: true);
      final store = RegisterStore(
        service: authRepository,
        storageService: _FakeSecureStorageRepository(),
      );

      store.validateUsername('AlyaPutri');
      await store.checkUsernameAvailability('AlyaPutri');

      expect(authRepository.lastCheckedUsername, 'alyaputri');
      expect(store.username, 'alyaputri');
      expect(store.isUsernameAvailable, isTrue);
      expect(store.error.username, isNull);
      expect(store.onCheckUsername, isFalse);
    });

    test('sets username error when unavailable', () async {
      final store = RegisterStore(
        service: _FakeAuthRepository(usernameAvailable: false),
        storageService: _FakeSecureStorageRepository(),
      );

      await store.checkUsernameAvailability('takenname');

      expect(store.isUsernameAvailable, isFalse);
      expect(store.error.username, 'Username sudah digunakan');
      expect(store.onCheckUsername, isFalse);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.usernameAvailable = true});

  final bool usernameAvailable;
  String? lastCheckedUsername;

  @override
  Future<bool> checkUsernameAvailable(String username) async {
    lastCheckedUsername = username;
    return usernameAvailable;
  }

  @override
  Future<bool> checkEmailAvailable({
    required String email,
    String? currentUid,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<UserModel?> authStateChanges() => const Stream.empty();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> changeProfilePicture({String? imageUrl}) {
    throw UnimplementedError();
  }

  @override
  String? get currentUid => null;

  @override
  Future<void> editUserProfile({
    required String uid,
    required EditProfileModel data,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> getUserProfile(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> refreshEmailVerification() {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String username,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<User?> reloadUser() {
    throw UnimplementedError();
  }

  @override
  Future<void> resendEmailVerification() {
    throw UnimplementedError();
  }

  @override
  Future<void> sendVerificationForChange({required String newEmail}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> syncChangedEmail({required String expectedEmail}) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateFcmToken({
    required String token,
    required String currentUid,
  }) {
    throw UnimplementedError();
  }
}

class _FakeSecureStorageRepository implements SecureStorageRepository {
  bool isLogin = false;
  String? userId;
  String? fcmToken;
  String? themeModeName;

  @override
  Future<void> clear() async {
    isLogin = false;
    userId = null;
    fcmToken = null;
  }

  @override
  Future<String?> getFcmToken() async => fcmToken;

  @override
  Future<List<int>> getHiveEncryptionKey() async => List.filled(32, 1);

  @override
  Future<bool> getIsLogin() async => isLogin;

  @override
  Future<String?> getThemeModeName() async => themeModeName;

  @override
  Future<String?> getUserId() async => userId;

  @override
  Future<void> setFcmToken(String token) async {
    fcmToken = token;
  }

  @override
  Future<void> setIsLogin(bool value) async {
    isLogin = value;
  }

  @override
  Future<void> setThemeModeName(String value) async {
    themeModeName = value;
  }

  @override
  Future<void> setUserId(String token) async {
    userId = token;
  }
}

class _FakePresenceRepository implements PresenceRepository {
  @override
  Future<void> setOffline() {
    throw UnimplementedError();
  }

  @override
  Future<void> setOnline() {
    throw UnimplementedError();
  }
}
