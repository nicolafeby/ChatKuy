import 'package:chatkuy/core/config/env_config.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService implements AuthRepository {
  AuthService(this.auth, this.firestore);

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  @override
  Stream<UserModel?> authStateChanges() {
    return auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      final doc = await firestore.collection(EnvConfig.usersCollection).doc(user.uid).get();

      return UserModel.fromJson(doc.data()!).copyWith(id: doc.id);
    });
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    final cred = await auth.signInWithEmailAndPassword(email: email, password: password);

    final doc = await firestore.collection(EnvConfig.usersCollection).doc(cred.user!.uid).get();

    return UserModel.fromJson(doc.data()!).copyWith(id: doc.id);
  }

  @override
  Future<UserModel> register({required String email, required String password, required String name}) async {
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);

    final user = UserModel(id: cred.user!.uid, name: name, email: email);

    await firestore.collection(EnvConfig.usersCollection).doc(user.id).set(user.toJson());

    return user;
  }

  @override
  Future<void> logout() {
    return auth.signOut();
  }
}
