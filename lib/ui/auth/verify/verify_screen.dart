import 'dart:async';

import 'package:chatkuy/app_context.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/auth/register/register_store.dart';
import 'package:chatkuy/stores/profile/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

enum VerificationType {
  email,
  editEmail,
}

class VerifyArgument {
  final String email;
  final VerificationType type;
  const VerifyArgument(
      {required this.email, this.type = VerificationType.email});
}

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  RegisterStore store = RegisterStore(
    service: getIt<AuthRepository>(),
    storageService: getIt<SecureStorageRepository>(),
  );
  ProfileStore profileStore = ProfileStore(
    presenceRepository: getIt<PresenceRepository>(),
    authRepository: getIt<AuthRepository>(),
    storageRepository: getIt<SecureStorageRepository>(),
  );

  List<ReactionDisposer> _reaction = [];
  Timer? _verificationTimer;
  VerifyArgument? argument;
  bool _isCheckingVerification = false;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as VerifyArgument?;
    if (argument?.type != VerificationType.editEmail) {
      store.initAuthListener();
    }
    _startTimerPeriodic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (argument?.type == VerificationType.editEmail) return;

      _reaction = [
        reaction((p0) => store.registerResponse?.isEmailVerified, (p0) async {
          if (p0 == true) {
            await Future.delayed(Duration(milliseconds: 200));
            if (argument?.type == VerificationType.editEmail) {
              Get.back(result: true);
            } else {
              Get.offAllNamed(AppRouteName.BASE_SCREEN);
            }
          }
        }),
      ];
    });
  }

  void _startTimerPeriodic() {
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) async {
        if (_isCheckingVerification) return;
        _isCheckingVerification = true;

        if (argument?.type == VerificationType.editEmail) {
          final synced =
              await profileStore.syncChangedEmail(argument?.email ?? '');
          if (synced) {
            Get.back(result: true);
          } else if (profileStore.error.general?.code == 'user-token-expired') {
            _verificationTimer?.cancel();
            await AppContext.sessionStore.logout();
            _showReloginRequiredBottomSheet();
          }
          _isCheckingVerification = false;
          return;
        }

        await store.refreshEmailVerification();
        _isCheckingVerification = false;
      },
    );
  }

  @override
  void dispose() {
    for (var d in _reaction) {
      d();
    }
    _verificationTimer?.cancel();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Verifikasi Email',
              style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
            ),
            16.verticalSpace,
            Text(
              'Buka email ${argument?.email} dan klik link verifikasi yang kami kirim',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            32.verticalSpace,
            ButtonWidget.withCountdown(
              title: 'Kirim Ulang Link',
              initCountdown: true,
              onPressed: _resendVerification,
              value: 1,
              unit: CountdownUnit.minutes,
            ),
          ],
        ).paddingAll(20.r),
      ),
    );
  }

  void _resendVerification() {
    if (argument?.type == VerificationType.editEmail) {
      profileStore.authRepository.sendVerificationForChange(
        newEmail: argument?.email ?? '',
      );
      return;
    }

    store.resendEmailVerification();
  }

  void _showReloginRequiredBottomSheet() {
    if (Get.isBottomSheetOpen == true) return;

    Get.bottomSheet(
      BottomsheetWidget(
        title: 'Email Berhasil Diubah',
        message:
            'Email baru kamu sudah berhasil diverifikasi. Untuk keamanan akun, silakan login ulang menggunakan username dan password kamu.',
        buttonText: 'Login Ulang',
        restricBackNative: true,
        onButtonPressed: () => Get.offAllNamed(AppRouteName.LOGIN_SCREEN),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }
}
