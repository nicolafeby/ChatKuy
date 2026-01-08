import 'package:chatkuy/data/models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> authStateChanges();

  Future<UserModel> login({required String email, required String password});

  Future<UserModel> register({required String email, required String password, required String name});

  Future<bool> refreshEmailVerification();

  Future<void> resendEmailVerification() ;

  Future<void> logout();
}
