// ignore_for_file: library_private_types_in_public_api

import 'package:mobx/mobx.dart';
import 'package:get/get.dart';

part 'login_store.g.dart';

class LoginStore = _LoginStore with _$LoginStore;

abstract class _LoginStore with Store {
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

  
  bool get isValid => errorEmail == null && password != null && email != null;
}
