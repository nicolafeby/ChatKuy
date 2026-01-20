import 'dart:async';

import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/auth/register/register_store.dart';
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
  const VerifyArgument({required this.email, this.type = VerificationType.email});
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

  List<ReactionDisposer> _reaction = [];
  VerifyArgument? argument;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as VerifyArgument?;
    store.initAuthListener();
    _startTimerPeriodic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reaction = [
        reaction((p0) => store.registerResponse?.isEmailVerified, (p0) async {
          if (p0 == true) {
            await Future.delayed(Duration(milliseconds: 200));
            if (argument?.type == VerificationType.editEmail) {
              Get.back<bool>(result: true);
            } else {
              Get.offAllNamed(AppRouteName.BASE_SCREEN);
            }
          }
        }),
      ];
    });
  }

  void _startTimerPeriodic() {
    Timer.periodic(Duration(milliseconds: 1500), (_) async {
      await store.refreshEmailVerification();
    });
  }

  @override
  void dispose() {
    for (var d in _reaction) {
      d();
    }
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
              onPressed: () => store.resendEmailVerification(),
              value: 1,
              unit: CountdownUnit.minutes,
            ),
          ],
        ).paddingAll(20.r),
      ),
    );
  }
}
