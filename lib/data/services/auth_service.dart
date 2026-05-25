import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/utils/extension/user_model_fields.dart';
import 'package:chatkuy/data/models/edit_profile_model.dart';
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

      final doc = await firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      return UserModel.fromJson(doc.data()!).copyWith(id: doc.id);
    });
  }

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final query = await firestore
        .collection(FirebaseCollections.users)
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
    final pendingEmail =
        userDoc.data()[UserModelFields.pendingEmail] as String?;

    UserCredential cred;
    String emailUsed = userData.email;

    try {
      cred = await auth.signInWithEmailAndPassword(
        email: userData.email,
        password: password,
      );
    } on FirebaseAuthException catch (_) {
      if (pendingEmail == null || pendingEmail.isEmpty) rethrow;

      cred = await auth.signInWithEmailAndPassword(
        email: pendingEmail,
        password: password,
      );
      emailUsed = pendingEmail;
    }

    final firebaseUser = cred.user!;

    if (!firebaseUser.emailVerified) {
      throw FirebaseAuthException(
          code: AppStrings.emailNotVerified, email: emailUsed);
    }

    final userRef =
        firestore.collection(FirebaseCollections.users).doc(userDoc.id);

    final updatedUser = userData.copyWith(
      email: emailUsed,
      isOnline: true,
      lastOnlineAt: DateTime.now(),
    );

    await userRef.update({
      ...updatedUser.toJson(),
      UserModelFields.pendingEmail: FieldValue.delete(),
    });

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

    await firestore
        .collection(FirebaseCollections.users)
        .doc(user.id)
        .set(user.toJson());

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

    final doc = await firestore
        .collection(FirebaseCollections.users)
        .doc(firebaseUser.uid)
        .get();

    final currentUser = UserModel.fromJson(doc.data()!);

    final updatedUser = currentUser.copyWith(
      email: firebaseUser.email,
      isEmailVerified: true,
    );

    await firestore
        .collection(FirebaseCollections.users)
        .doc(firebaseUser.uid)
        .update({
      ...updatedUser.toJson(),
      UserModelFields.pendingEmail: FieldValue.delete(),
    });

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
        .collection(FirebaseCollections.users)
        .where(
          UserModelFields.username,
          isEqualTo: username.toLowerCase(),
        )
        .limit(1)
        .get();

    return query.docs.isEmpty;
  }

  @override
  Future<bool> checkEmailAvailable({
    required String email,
    String? currentUid,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final emailsToCheck = {
      email.trim(),
      normalizedEmail,
    };

    for (final emailToCheck in emailsToCheck) {
      final query = await firestore
          .collection(FirebaseCollections.users)
          .where(
            UserModelFields.email,
            isEqualTo: emailToCheck,
          )
          .limit(1)
          .get();

      if (query.docs.isEmpty) continue;

      final matchedDoc = query.docs.first;
      if (currentUid != null && matchedDoc.id == currentUid) continue;

      return false;
    }

    return true;
  }

  @override
  Future<void> logout() {
    return auth.signOut();
  }

  @override
  Future<void> updateFcmToken(
      {required String token, required String currentUid}) async {
    await firestore
        .collection(FirebaseCollections.users)
        .doc(currentUid)
        .update(
      {AppStrings.fcmToken: token},
    );
  }

  @override
  Future<UserModel> getUserProfile(String uid) async {
    final doc =
        await firestore.collection(FirebaseCollections.users).doc(uid).get();

    if (!doc.exists) {
      throw Exception('User profile not found');
    }

    final userData = UserModel.fromJson(doc.data()!);
    return userData;
  }

  @override
  Future<void> editUserProfile(
      {required String uid, required EditProfileModel data}) async {
    await firestore
        .collection(FirebaseCollections.users)
        .doc(uid)
        .update(data.toJson());
  }

  @override
  Future<void> sendVerificationForChange({
    required String newEmail,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    await firestore.collection(FirebaseCollections.users).doc(user.uid).update({
      UserModelFields.pendingEmail: newEmail,
    });

    await user.verifyBeforeUpdateEmail(newEmail);
  }

  @override
  Future<bool> syncChangedEmail({
    required String expectedEmail,
  }) async {
    final user = auth.currentUser;

    if (user == null) return false;

    await user.reload();

    final reloadedUser = auth.currentUser;
    final verifiedEmail = reloadedUser?.email;

    if (verifiedEmail == null ||
        verifiedEmail.toLowerCase() != expectedEmail.toLowerCase()) {
      return false;
    }

    await firestore
        .collection(FirebaseCollections.users)
        .doc(reloadedUser!.uid)
        .update({
      UserModelFields.email: verifiedEmail,
      UserModelFields.pendingEmail: FieldValue.delete(),
      UserModelFields.isEmailVerified: true,
    });

    return true;
  }

  @override
  Future<User?> reloadUser() async {
    final user = auth.currentUser;

    if (user == null) return null;

    await user.reload();
    return auth.currentUser;
  }

  @override
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final email = user.email;
    if (email == null) {
      throw Exception('Email user tidak ditemukan');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    await user.updatePassword(newPassword);
  }

  @override
  Future<void> changeProfilePicture({String? imageUrl}) async {
    await firestore
        .collection(FirebaseCollections.users)
        .doc(currentUid)
        .update({FriendField.photoUrl: imageUrl});
  }

  @override
  String? get currentUid => auth.currentUser?.uid;
}
