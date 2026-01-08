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
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cred = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;

    if (!user.emailVerified) {
      throw Exception('email-not-verified');
    }

    final doc = await firestore.collection(EnvConfig.usersCollection).doc(user.uid).get();

    return UserModel.fromJson(doc.data()!).copyWith(id: doc.id);
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = cred.user!;

    // 1️⃣ Kirim email verifikasi
    if (!firebaseUser.emailVerified) {
      await firebaseUser.sendEmailVerification();
    }

    // 2️⃣ Simpan user ke Firestore
    final user = UserModel(
      id: firebaseUser.uid,
      name: name,
      email: email,
      isEmailVerified: false, // optional
    );

    await firestore.collection(EnvConfig.usersCollection).doc(user.id).set(user.toJson());

    return user;
  }

  @override
  Future<bool> refreshEmailVerification() async {
    final firebaseUser = auth.currentUser;
    if (firebaseUser == null) return false;

    await firebaseUser.reload();

    if (!firebaseUser.emailVerified) {
      return false;
    }

    final doc = await firestore.collection(EnvConfig.usersCollection).doc(firebaseUser.uid).get();

    final currentUser = UserModel.fromJson(doc.data()!);

    final updatedUser = currentUser.copyWith(
      isEmailVerified: true,
    );

    await firestore.collection(EnvConfig.usersCollection).doc(firebaseUser.uid).update(updatedUser.toJson());

    return true;
  }

  @override
  Future<void> resendEmailVerification() async {
    final user = auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> logout() {
    return auth.signOut();
  }
}
