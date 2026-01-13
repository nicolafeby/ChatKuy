import 'dart:developer';
import 'dart:ui';

import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/data/services/presence_service.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
}

class ProfileErrorStore = _ProfileErrorStore with _$ProfileErrorStore;

abstract class _ProfileErrorStore with Store {
  @observable
  FirebaseException? general;
}
