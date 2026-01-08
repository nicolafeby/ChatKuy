// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:mobx/mobx.dart';
import 'package:get/get.dart';

part 'register_store.g.dart';

class RegisterStore = _RegisterStore with _$RegisterStore;

abstract class _RegisterStore with Store {
  final AuthRepository service;
  _RegisterStore({required this.service});

  final error = RegisterErrorStore();

  @observable
  String? name;

  @observable
  String? email;

  @observable
  String? password;

  StreamSubscription<UserModel?>? _authSub;

  @observable
  UserModel? currentUser;

  @observable
  ObservableFuture<UserModel?>? registerFuture;

  @observable
  ObservableFuture<bool>? emailVerificationFuture;

  void initAuthListener() {
    _authSub = service.authStateChanges().listen(
      (user) {
        currentUser = user;
      },
    );
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
  void register() {
    error.general = null;

    registerFuture = ObservableFuture(
      service.register(
        email: email ?? '',
        password: password ?? '',
        name: name ?? '',
      ),
    );

    registerFuture!.then((user) {
      currentUser = user;
    }).catchError((e) {
      error.general = e.toString();
    });
  }

  @action
  void refreshEmailVerification() {
    error.general = null;

    emailVerificationFuture = ObservableFuture(
      service.refreshEmailVerification(),
    );

    emailVerificationFuture!.then((verified) {
      if (verified && currentUser != null) {
        currentUser = currentUser!.copyWith(isEmailVerified: true);
      }
    }).catchError((e) {
      error.general = e.toString();
    });
  }

  @action
  Future<void> resendEmailVerification() async {
    try {
      await service.resendEmailVerification();
    } catch (e) {
      error.general = e.toString();
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
  String? general;
}
