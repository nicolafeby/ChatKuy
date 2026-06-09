import 'package:chatkuy/data/models/edit_profile_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<bool> checkEmailAvailable({
    required String email,
    String? currentUid,
  });

  Future<void> logout();

  Future<void> updateFcmToken(
      {required String token, required String currentUid});

  Future<UserModel> getUserProfile(String uid);

  Future<void> editUserProfile(
      {required String uid, required EditProfileModel data});

  Future<void> sendVerificationForChange({
    required String newEmail,
  });

  Future<bool> syncChangedEmail({
    required String expectedEmail,
  });

  /// Reload user setelah verifikasi berhasil
  Future<User?> reloadUser();

  /// Re-authentication jika diperlukan
  Future<void> reauthenticate({
    required String email,
    required String password,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> changeProfilePicture({String? imageUrl});

  Future<void> requestAccountDeletion({required String password});

  String? get currentUid;
}
