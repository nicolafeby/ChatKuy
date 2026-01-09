// ignore_for_file: library_private_types_in_public_api

import 'dart:developer';

import 'package:chatkuy/app_context.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:get/get.dart';

part 'login_store.g.dart';

class LoginStore = _LoginStore with _$LoginStore;

abstract class _LoginStore with Store {
  final AuthRepository service;
  final SecureStorageRepository storageService;
  _LoginStore({
    required this.service,
    required this.storageService,
  });

  @observable
  String? email;

  @observable
  String? password;

  final error = LoginErrorStore();

  @observable
  ObservableFuture<UserModel?>? loginFuture;

  @observable
  UserModel? loginResponse;

  @action
  void validateEmail(String value) {
    email = value;
    if (email?.isEmpty == true) {
      error.email = 'Email tidak boleh kosong';
    } else if (!GetUtils.isEmail(email!)) {
      error.email = 'Format email tidak valid';
    } else {
      error.email = null;
    }
  }

  @action
  Future<void> login({required VoidCallback onSuccess}) async {
    error.general = null;

    try {
      final future = service.login(
        email: email ?? '',
        password: password ?? '',
      );

      loginFuture = ObservableFuture(future);

      final resp = await future;

      loginResponse = resp;

      await AppContext.sessionStore.setLoggedIn(true);
      onSuccess.call();
    } on FirebaseAuthException catch (e) {
      log('🔥 FirebaseAuthException');
      log('➡️ code    : ${e.code}');
      log('➡️ message : ${e.message}');

      error.general = e;
    } on FirebaseException catch (e) {
      log('🔥 FirebaseException');
      log('➡️ plugin  : ${e.plugin}');
      log('➡️ code    : ${e.code}');
      log('➡️ message : ${e.message}');

      error.general = FirebaseAuthException(
        code: e.code,
        message: e.message,
      );
    } catch (e) {
      log('❌ Unknown error: $e');

      error.general = FirebaseAuthException(
        code: e.toString(),
        message: e.toString(),
      );
    }
  }

  @action
  Future<void> logout({required VoidCallback onSuccess}) async {
    error.general = null;

    try {
      await service.logout();
    } catch (e, s) {
      log('⚠️ Logout failed, continuing anyway');
      log('$e');
      log('$s');
    } finally {
      await storageService.clear();
      await Future.delayed(Duration(milliseconds: 200));
      onSuccess.call();
    }
  }

  bool get isValid => error.email == null && password != null && email != null;
}

class LoginErrorStore = _LoginErrorStore with _$LoginErrorStore;

abstract class _LoginErrorStore with Store {
  @observable
  String? email;

  @observable
  FirebaseException? general;
}
