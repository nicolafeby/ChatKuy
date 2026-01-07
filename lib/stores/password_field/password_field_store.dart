// ignore_for_file: library_private_types_in_public_api

import 'package:mobx/mobx.dart';

part 'password_field_store.g.dart';

class PasswordFieldStore = _PasswordFieldStore with _$PasswordFieldStore;

abstract class _PasswordFieldStore with Store {
  @observable
  String password = '';

  @observable
  bool isPasswordVisible = false;

  @action
  void setPassword(String value) => password = value;

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
  bool get isPasswordValid => passwordError == null && password.isNotEmpty;
}
