import 'dart:developer';
import 'dart:ui';

import 'package:chatkuy/data/models/edit_profile_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/data/services/presence_service.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/ui/profile/edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'profile_store.g.dart';

class ProfileStore = _ProfileStore with _$ProfileStore;

abstract class _ProfileStore with Store {
  _ProfileStore({
    required this.presenceRepository,
    required this.authRepository,
    required this.storageRepository,
  }) {
    getAppVersion();
  }
  final PresenceRepository presenceRepository;
  final AuthRepository authRepository;
  final SecureStorageRepository storageRepository;

  @observable
  String? appVersion;

  final error = ProfileErrorStore();

  @observable
  bool loading = false;

  @action
  Future getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion = info.version;
  }

  @action
  Future<void> logout({required VoidCallback onSuccess}) async {
    error.general = null;

    try {
      await presenceRepository.setOffline();
      await authRepository.logout();
    } catch (e) {
      log('⚠️ Logout failed, continuing anyway');
      log('$e');
    } finally {
      await getIt<PresenceService>().setOffline();
      await storageRepository.clear();
      await Future.delayed(Duration(milliseconds: 200));
      onSuccess.call();
    }
  }

  @observable
  ObservableFuture<UserModel>? userFuture;

  @computed
  UserModel? get user => userFuture?.value;

  @action
  Future<void> getUserProfile(String uid) async {
    error.general = null;

    try {
      final future = authRepository.getUserProfile(uid);

      userFuture = ObservableFuture(future);

      // Optional: tunggu untuk capture error
      await future;
    } on FirebaseException catch (e) {
      error.general = e;
    } catch (e) {
      error.general = FirebaseException(plugin: e.toString());

      rethrow;
    }
  }

  @observable
  EditProfileArgument? argument;

  @action
  void initEditProfile() {
    argument = Get.arguments as EditProfileArgument?;
    final data = argument?.userData;

    if (data == null) return;
    editProfileData = data;
  }

  @action
  void validateEditName(String value) {
    if (value.isEmpty) {
      error.name = 'Nama tidak boleh kosong';
    } else {
      error.name = null;
      editProfileData = editProfileData?.copyWith(
        name: value.trim(),
      );
    }
  }

  @action
  void validateEditUsername(String value) {
    if (value.isEmpty) {
      error.name = 'Username tidak boleh kosong';
    } else {
      error.name = null;
      editProfileData = editProfileData?.copyWith(
        username: value.trim(),
      );
    }
  }

  @action
  void validateEditEmail(String value) {
    if (value.isEmpty) {
      error.name = 'Email tidak boleh kosong';
    } else {
      error.name = null;
      editProfileData = editProfileData?.copyWith(
        email: value.trim(),
      );
    }
  }

  @observable
  EditProfileModel? editProfileData;

  @observable
  ObservableFuture<void>? editProfileFuture;

  @action
  Future<void> editProfile() async {
    try {
      final id = await storageRepository.getUserId();

      if (id == null || editProfileData == null) return;
      final future = authRepository.editUserprofile(uid: id, data: editProfileData!);

      editProfileFuture = ObservableFuture(future);
      await editProfileFuture;
    } on FirebaseException catch (e) {
      error.general = e;
    } catch (e) {
      error.general = FirebaseException(plugin: e.toString());
      rethrow;
    }
  }

  @computed
  bool get hasProfileChanged => argument?.userData != editProfileData;
}

class ProfileErrorStore = _ProfileErrorStore with _$ProfileErrorStore;

abstract class _ProfileErrorStore with Store {
  @observable
  FirebaseException? general;

  @observable
  String? name;

  @observable
  String? username;

  @observable
  String? email;
}
