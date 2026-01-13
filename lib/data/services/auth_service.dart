import 'package:chatkuy/core/config/env_config.dart';
import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/utils/extension/user_model_fields.dart';
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
    required String username,
    required String password,
  }) async {
    final query = await firestore
        .collection(EnvConfig.usersCollection)
        .where(
          UserModelFields.username,
          isEqualTo: username.toLowerCase(),
        )
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception(AppStrings.userNotFound);
    }

    final userDoc = query.docs.first;
    final userData = UserModel.fromJson(userDoc.data());

    final cred = await auth.signInWithEmailAndPassword(
      email: userData.email,
      password: password,
    );

    final firebaseUser = cred.user!;

    if (!firebaseUser.emailVerified) {
      throw FirebaseAuthException(code: AppStrings.emailNotVerified, email: userData.email);
    }

    final userRef = firestore.collection(EnvConfig.usersCollection).doc(userDoc.id);

    final updatedUser = userData.copyWith(
      isOnline: true,
      lastOnlineAt: DateTime.now(),
    );

    await userRef.update(updatedUser.toJson());

    return updatedUser.copyWith(id: userDoc.id);
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = cred.user!;

    if (!firebaseUser.emailVerified) {
      await firebaseUser.sendEmailVerification();
    }

    final user = UserModel(
      id: firebaseUser.uid,
      name: name,
      email: email,
      username: username,
      isEmailVerified: false,
      isOnline: false,
      fcmToken: '',
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
  Future<bool> checkUsernameAvailable(String username) async {
    final query = await firestore
        .collection(EnvConfig.usersCollection)
        .where(
          UserModelFields.username,
          isEqualTo: username.toLowerCase(),
        )
        .limit(1)
        .get();

    return query.docs.isEmpty;
  }

  @override
  Future<void> logout() {
    return auth.signOut();
  }

  @override
  Future<void> updateFcmToken({required String token, required String currentUid}) async {
    await FirebaseFirestore.instance.collection(EnvConfig.usersCollection).doc(currentUid).update(
      {'fcmToken': token},
    );
  }

  @override
  Future<UserModel> getUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance.collection(EnvConfig.usersCollection).doc(uid).get();

    if (!doc.exists) {
      throw Exception('User profile not found');
    }

    final userData = UserModel.fromJson(doc.data()!);
    return userData;
  }

  @override
  String? get currentUid => auth.currentUser?.uid;
}
