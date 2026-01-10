import 'package:chatkuy/data/models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> authStateChanges();

  Future<UserModel> login({required String username, required String password});

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String username,
  });

  Future<bool> refreshEmailVerification();

  Future<void> resendEmailVerification();

  Future<bool> checkUsernameAvailable(String username);

  Future<void> logout();

  String? get currentUid;
}
