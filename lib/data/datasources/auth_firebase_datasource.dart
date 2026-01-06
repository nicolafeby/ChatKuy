import 'package:firebase_auth/firebase_auth.dart';

class AuthFirebaseDatasource {
  final FirebaseAuth auth;

  AuthFirebaseDatasource(this.auth);

  Future<UserCredential> login(
    String email,
    String password,
  ) {
    return auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> register(
    String email,
    String password,
  ) {
    return auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() => auth.signOut();

  User? get currentUser => auth.currentUser;
}
