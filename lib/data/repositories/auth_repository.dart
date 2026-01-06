import 'package:chatkuy/data/datasources/auth_firebase_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final AuthFirebaseDatasource datasource;

  AuthRepository(this.datasource);

  Future<UserCredential> login(String email, String password) {
    return datasource.login(email, password);
  }

  Future<UserCredential> register(String email, String password) {
    return datasource.register(email, password);
  }

  Future<void> logout() => datasource.logout();

  User? get currentUser => datasource.currentUser;
}
