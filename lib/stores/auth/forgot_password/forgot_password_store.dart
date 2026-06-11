import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobx/mobx.dart';

part 'forgot_password_store.g.dart';

class ForgotPasswordStore = _ForgotPasswordStore with _$ForgotPasswordStore;

abstract class _ForgotPasswordStore with Store {
  final AuthRepository service;

  _ForgotPasswordStore({required this.service});

  final error = ForgotPasswordErrorStore();

  @observable
  String? identifier;

  @observable
  ObservableFuture<void>? resetPasswordFuture;

  @action
  void validateIdentifier(String value) {
    identifier = value.trim();

    if (identifier?.isEmpty == true) {
      error.identifier = 'Username atau email tidak boleh kosong';
    } else {
      error.identifier = null;
    }
  }

  @action
  Future<void> sendResetLink({required void Function() onSuccess}) async {
    error.general = null;

    try {
      final future = service.sendPasswordResetLink(
        identifier: identifier ?? '',
      );

      resetPasswordFuture = ObservableFuture(future);
      await resetPasswordFuture;
    } on FirebaseAuthException catch (e, stackTrace) {
      await AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Forgot password failed with FirebaseAuthException',
        context: {'auth_code': e.code},
        showBottomSheet: false,
      );

      error.general = e;
    } on FirebaseException catch (e, stackTrace) {
      await AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Forgot password failed with FirebaseException',
        showBottomSheet: false,
      );

      error.general = FirebaseAuthException(
        code: e.code,
        message: e.message,
      );
    } catch (e, stackTrace) {
      await AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Forgot password failed with unknown error',
        showBottomSheet: false,
      );

      error.general = FirebaseAuthException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  bool get isValid => error.identifier == null && identifier != null;
}

class ForgotPasswordErrorStore = _ForgotPasswordErrorStore
    with _$ForgotPasswordErrorStore;

abstract class _ForgotPasswordErrorStore with Store {
  @observable
  String? identifier;

  @observable
  FirebaseException? general;
}
