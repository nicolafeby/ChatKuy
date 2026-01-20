import 'dart:developer';
import 'dart:ui';

import 'package:chatkuy/core/constants/formatter.dart';
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
import 'package:flutter/material.dart';
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

  @observable
  String? name;

  @action
  void validateEditName(String value) {
    name = value;

    if (name?.isEmpty == true) {
      error.name = 'Nama tidak boleh kosong';
    } else if (name!.length < 3) {
      error.name = 'Nama minimal 3 karakter';
    } else if (name!.length > 50) {
      error.name = 'Nama maksimal 50 karakter';
    } else if (!AppFormatter.nameRegex.hasMatch(name!)) {
      error.name = 'Nama hanya boleh berisi huruf dan spasi';
    } else {
      error.name = null;
      editProfileData = editProfileData?.copyWith(name: name);
    }
  }

  @observable
  String? username;

  @action
  Future validateEditUsername(String value) async {
    username = value;
    final int letterCount = RegExp(r'[a-z]').allMatches(username ?? '').length;

    if (username?.isEmpty == true) {
      error.username = 'Username tidak boleh kosong';
    } else if ((letterCount) <= 5) {
      error.username = 'Username minimal 5 huruf';
    } else {
      error.username = null;
      await checkUsernameAvailability(username ?? '');
      if (isUsernameAvailable == true) {
        editProfileData = editProfileData?.copyWith(username: username);
      }
    }
  }

  @action
  void onChangeGender({required Gender gender}) {
    editProfileData = editProfileData?.copyWith(gender: gender);
  }

  @observable
  bool? isUsernameAvailable;

  @observable
  bool onCheckUsername = false;

  @action
  Future<void> checkUsernameAvailability(String value) async {
    username = value.trim().toLowerCase();

    onCheckUsername = true;
    error.username = null;

    try {
      final available = await authRepository.checkUsernameAvailable(username ?? '');

      isUsernameAvailable = available;

      if (!available) {
        error.username = 'Username sudah digunakan';
      }
    } catch (e) {
      error.username = 'Gagal mengecek username';
      isUsernameAvailable = null;
    } finally {
      onCheckUsername = false;
    }
  }

  @observable
  String? email;

  @action
  void validateEditEmail(String value) {
    email = value;
    if (email?.isEmpty == true) {
      error.email = 'Email tidak boleh kosong';
    } else if (!GetUtils.isEmail(email!)) {
      error.email = 'Format email tidak valid';
    } else {
      error.email = null;
      editProfileData = editProfileData?.copyWith(email: email);
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
      final future = authRepository.editUserProfile(uid: id, data: editProfileData!);

      editProfileFuture = ObservableFuture(future);
      await editProfileFuture;
    } on FirebaseException catch (e) {
      error.general = e;
    } catch (e) {
      error.general = FirebaseException(plugin: e.toString());
      rethrow;
    }
  }

  @observable
  String? password;

  @observable
  String? currentEmail;

  @action
  void validateEmail(String value) {
    email = value;
    if (!GetUtils.isEmail(email!)) {
      error.email = 'Format email tidak valid';
    } else if (email == currentEmail) {
      error.email = 'Email tidak boleh sama';
    } else {
      error.email = null;
    }
  }

  @computed
  bool get canChangeEmail => error.email == null && password != null;

  @computed
  bool get canSaveProfileChanged => !error.hasErrorForm && argument?.userData != editProfileData;
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

  @computed
  bool get hasErrorForm => name != null || username != null || email != null;
}
