// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:developer';

import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:get/get.dart';

part 'register_store.g.dart';

class RegisterStore = _RegisterStore with _$RegisterStore;

abstract class _RegisterStore with Store {
  final AuthRepository service;
  final SecureStorageRepository storageService;
  _RegisterStore({required this.service, required this.storageService});

  final error = RegisterErrorStore();

  @observable
  String? name;

  @observable
  String? email;

  @observable
  String? password;

  StreamSubscription<UserModel?>? _authSub;

  @observable
  UserModel? registerResponse;

  @observable
  ObservableFuture<UserModel?>? registerFuture;

  @observable
  ObservableFuture<void>? resendEmailFuture;

  @observable
  ObservableFuture<bool>? emailVerificationFuture;

  void initAuthListener() {
    _authSub = service.authStateChanges().listen((user) {
      registerResponse = user;
    });
  }

  final RegExp _nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'-]+$");

  @action
  void validateName(String value) {
    name = value;

    if (name?.isEmpty == true) {
      error.name = 'Nama tidak boleh kosong';
    } else if (name!.length < 3) {
      error.name = 'Nama minimal 3 karakter';
    } else if (name!.length > 50) {
      error.name = 'Nama maksimal 50 karakter';
    } else if (!_nameRegex.hasMatch(name!)) {
      error.name = 'Nama hanya boleh berisi huruf dan spasi';
    } else {
      error.name = null;
    }
  }

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
  Future<void> register({required VoidCallback onSuccessRegister}) async {
    try {
      error.general = null;

      final future = service.register(
        email: email ?? '',
        password: password ?? '',
        name: name ?? '',
      );

      registerFuture = ObservableFuture(future);

      final resp = await future;
      log('success register response: $resp');
      registerResponse = resp;
      onSuccessRegister.call();
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

      error.general = e;
    } catch (e) {
      // ❌ UNKNOWN ERROR
      log('❌ Unknown error: $e');

      error.general = FirebaseAuthException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @action
  Future<void> refreshEmailVerification() async {
    error.general = null;

    try {
      final future = service.refreshEmailVerification();
      emailVerificationFuture = ObservableFuture(future);

      final verified = await future;

      if (verified && registerResponse != null) {
        registerResponse = registerResponse!.copyWith(isEmailVerified: true);
      }
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
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @action
  Future<void> resendEmailVerification({VoidCallback? onSuccess}) async {
    error.general = null;

    try {
      final future = service.resendEmailVerification();
      resendEmailFuture = ObservableFuture(future);
      await resendEmailFuture;

      onSuccess?.call();
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
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  void dispose() {
    _authSub?.cancel();
  }

  bool get isValid => error.name == null && error.email == null && email != null && password != null;
}

class RegisterErrorStore = _RegisterErrorStore with _$RegisterErrorStore;

abstract class _RegisterErrorStore with Store {
  @observable
  String? email;

  @observable
  String? name;

  @observable
  FirebaseException? general;
}
