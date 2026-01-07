// ignore_for_file: library_private_types_in_public_api

import 'package:mobx/mobx.dart';

part 'password_field_store.g.dart';

enum PasswordType {
  verify,
  create,
}

class PasswordFieldStore = _PasswordFieldStore with _$PasswordFieldStore;

abstract class _PasswordFieldStore with Store {
  @observable
  String password = '';

  @observable
  String confirmPassword = '';

  @observable
  bool isPasswordVisible = false;

  @action
  void setPassword(String value) => password = value;

  @action
  void setConfirmPassword(String value) => confirmPassword = value;

  @action
  void toggleVisibility() => isPasswordVisible = !isPasswordVisible;

  // Logic Validasi menggunakan Computed (Reactive)
  @computed
  String? get passwordError {
    if (password.isEmpty) return null; // Jangan tampilkan error jika belum mengetik

    if (password.length < 8) return 'Minimal 8 karakter';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Butuh 1 huruf besar';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'Butuh 1 huruf kecil';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Butuh 1 angka';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return 'Butuh 1 karakter spesial';

    return null; // Valid
  }

  @computed
  bool get isVerifyPasswordValid => passwordError == null && password.isNotEmpty;

  @computed
  String? get confirmPasswordError {
    if (confirmPassword.isEmpty) return null;
    if (confirmPassword != password) {
      return 'Konfirmasi password tidak cocok';
    }
    return null;
  }

  @computed
  bool get createPasswordPassed =>
      passwordError == null && confirmPasswordError == null && password.isNotEmpty && confirmPassword.isNotEmpty;
}
