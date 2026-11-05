import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/utils/extension/user_model_fields.dart';
import 'package:chatkuy/data/models/edit_profile_model.dart';
import 'package:chatkuy/data/models/user_email_update_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/models/user_update_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/services/firestore_model_converters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService implements AuthRepository {
  AuthService(this.auth, this.firestore);

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  CollectionReference<UserModel> get _usersRef =>
      FirestoreModelConverters.usersRef(firestore);

  @override
  Stream<UserModel?> authStateChanges() {
    return auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      final doc = await firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      final data = doc.data();
      if (!doc.exists || data == null) {
        await auth.signOut();
        return null;
      }

      if (_isDeletedAccount(data[UserModelFields.accountStatus])) {
        await auth.signOut();
        return null;
      }

      return FirestoreModelConverters.userFromSnapshot(doc);
    });
  }

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final emailUsed = username.trim().toLowerCase();
    final cred = await auth.signInWithEmailAndPassword(
      email: emailUsed,
      password: password,
    );

    final firebaseUser = cred.user!;

    if (!firebaseUser.emailVerified) {
      throw FirebaseAuthException(
          code: AppStrings.emailNotVerified, email: emailUsed);
    }

    final userRef =
        firestore.collection(FirebaseCollections.users).doc(firebaseUser.uid);
    final userDoc = await userRef.get();
    final rawUserData = userDoc.data();
    if (rawUserData == null ||
        _isDeletedAccount(rawUserData[UserModelFields.accountStatus])) {
      await auth.signOut();
      throw FirebaseAuthException(
        code: 'account-deleted',
        message: 'Akun tidak tersedia',
      );
    }
    final userData = FirestoreModelConverters.userFromSnapshot(userDoc);

    final lastOnlineAt = DateTime.now();
    final updatedUser = userData.copyWith(
      email: emailUsed,
      isOnline: true,
      lastOnlineAt: lastOnlineAt,
    );

    await userRef.update(
      UserEmailUpdateModel.loginVerified(
        email: emailUsed,
        lastOnlineAt: lastOnlineAt,
      ).toFirestoreJson(),
    );

    return updatedUser.copyWith(id: firebaseUser.uid);
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
      username: username.trim().toLowerCase(),
      isEmailVerified: false,
      isOnline: false,
      fcmToken: '',
    );

    final batch = firestore.batch();
    batch.set(
      firestore.collection(FirebaseCollections.usernames).doc(user.username),
      {'uid': user.id},
    );
    batch.set(
      firestore.collection(FirebaseCollections.users).doc(user.id),
      user.toJson(),
    );

    try {
      await batch.commit();
    } catch (_) {
      await firebaseUser.delete();
      rethrow;
    }

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

    final doc = await _usersRef.doc(firebaseUser.uid).get();

    final currentUser = doc.data();
    if (currentUser == null) {
      throw StateError('User ${firebaseUser.uid} not found');
    }

    final verifiedEmail = firebaseUser.email;
    if (verifiedEmail == null || verifiedEmail.isEmpty) {
      return false;
    }

    await firestore
        .collection(FirebaseCollections.users)
        .doc(firebaseUser.uid)
        .update(
          UserEmailUpdateModel.verified(email: verifiedEmail).toFirestoreJson(),
        );

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
  Future<void> sendPasswordResetLink({required String identifier}) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    if (normalizedIdentifier.isEmpty || !normalizedIdentifier.contains('@')) {
      return;
    }
    await auth.sendPasswordResetEmail(email: normalizedIdentifier);
  }

  @override
  Future<bool> checkUsernameAvailable(String username) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty) return false;
    final doc = await firestore
        .collection(FirebaseCollections.usernames)
        .doc(normalizedUsername)
        .get();
    return !doc.exists;
  }

  @override
  Future<bool> checkEmailAvailable({
    required String email,
    String? currentUid,
  }) async {
    // Firebase Auth remains the authority for email uniqueness. Querying a
    // private users collection before authentication would expose user emails.
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
          UserUpdateModel.fcmToken(token).toFirestoreJson(),
        );
  }

  @override
  Future<UserModel> getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();

    if (!doc.exists) {
      throw Exception('User profile not found');
    }

    final userData = doc.data();
    if (userData == null) {
      throw Exception('User profile not found');
    }
    return userData;
  }

  @override
  Future<void> editUserProfile(
      {required String uid, required EditProfileModel data}) async {
    final userRef = firestore.collection(FirebaseCollections.users).doc(uid);
    final current = await userRef.get();
    final oldUsername = current.data()?[UserModelFields.username] as String?;
    final newUsername = data.username.trim().toLowerCase();
    final batch = firestore.batch();

    if (oldUsername != newUsername) {
      batch.set(
        firestore.collection(FirebaseCollections.usernames).doc(newUsername),
        {'uid': uid},
      );
      if (oldUsername != null && oldUsername.isNotEmpty) {
        batch.delete(
          firestore.collection(FirebaseCollections.usernames).doc(oldUsername),
        );
      }
    }

    batch.update(userRef, {
      ...data.toJson(),
      UserModelFields.username: newUsername,
    });
    await batch.commit();
  }

  @override
  Future<void> sendVerificationForChange({
    required String newEmail,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    await firestore.collection(FirebaseCollections.users).doc(user.uid).update(
          UserEmailUpdateModel.pendingVerification(email: newEmail)
              .toFirestoreJson(),
        );

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
        .update(
          UserEmailUpdateModel.verified(email: verifiedEmail).toFirestoreJson(),
        );

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
        .update(UserUpdateModel.profilePicture(imageUrl).toFirestoreJson());
  }

  @override
  Future<void> requestAccountDeletion({required String password}) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw Exception('Email user tidak ditemukan');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);

    await firestore
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .update(UserUpdateModel.accountDeletionRequested().toFirestoreJson());

    await auth.signOut();
  }

  @override
  String? get currentUid => auth.currentUser?.uid;

  bool _isDeletedAccount(dynamic status) {
    return status == AccountStatus.pendingDelete ||
        status == AccountStatus.deleted;
  }
}
