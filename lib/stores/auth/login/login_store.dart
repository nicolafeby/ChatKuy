import 'dart:developer';

import 'package:chatkuy/app_context.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/data/services/presence_service.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'login_store.g.dart';

class LoginStore = _LoginStore with _$LoginStore;

abstract class _LoginStore with Store {
  final AuthRepository service;
  final SecureStorageRepository storageService;
  final PresenceRepository presenceService;
  _LoginStore({
    required this.service,
    required this.storageService,
    required this.presenceService,
  });

  @observable
  String? username;

  @observable
  String? password;

  @observable
  String? email;

  final error = LoginErrorStore();

  @observable
  ObservableFuture<UserModel?>? loginFuture;

  @observable
  UserModel? loginResponse;

  @action
  void validateUsername(String value) {
    username = value;

    final int letterCount = RegExp(r'[a-z]').allMatches(username ?? '').length;

    if (username?.isEmpty == true) {
      error.username = 'Username tidak boleh kosong';
    } else if ((letterCount) <= 5) {
      error.username = 'Username minimal 5 huruf';
    } else {
      error.username = null;
    }
  }

  @action
  Future<void> login({
    required VoidCallback onSuccess,
  }) async {
    error.general = null;

    try {
      final future = service.login(
        username: username ?? '',
        password: password ?? '',
      );

      loginFuture = ObservableFuture(future);

      final resp = await loginFuture;

      if (resp == null) return;

      loginResponse = resp;

      await AppContext.sessionStore.setLoggedIn(true);
      await storageService.setUserId(resp.id);

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await storageService.setFcmToken(token);

      service.updateFcmToken(token: token, currentUid: resp.id);

      await Future.delayed(const Duration(milliseconds: 200));

      onSuccess.call();
    } on FirebaseAuthException catch (e) {
      email = e.email;

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
      log('❌ Unknown error');
      log(e.toString());

      error.general = FirebaseAuthException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  bool get isValid => error.username == null && password != null && username != null;
}

class LoginErrorStore = _LoginErrorStore with _$LoginErrorStore;

abstract class _LoginErrorStore with Store {
  @observable
  String? username;

  @observable
  FirebaseException? general;
}
