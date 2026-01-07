// ignore_for_file: library_private_types_in_public_api

import 'package:mobx/mobx.dart';
import 'package:get/get.dart';

part 'register_store.g.dart';

class RegisterStore = _RegisterStore with _$RegisterStore;

abstract class _RegisterStore with Store {
  @observable
  String? email;

  @observable
  String? password;

  @observable
  String? errorEmail;

  @action
  void validateEmail(String value) {
    email = value;
    if (email?.isEmpty == true) {
      errorEmail = 'Email tidak boleh kosong';
    } else if (!GetUtils.isEmail(email!)) {
      errorEmail = 'Format email tidak valid';
    } else {
      errorEmail = null;
    }
  }

  bool get isValid => errorEmail == null && email != null && password != null;
}
