import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_password_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_widget.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/auth/register/register_store.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:mobx/mobx.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with BaseLayout {
  RegisterStore store = RegisterStore(
    service: getIt<AuthRepository>(),
  );

  List<ReactionDisposer> _reaction = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reaction = [
        reaction((p0) => store.registerFuture?.status, (p0) {
          if (p0 == FutureStatus.pending) {
            showLoading();
          } else {
            dismissLoading();
          }
        }),
        reaction((p0) => store.error.general, (p0) {
          if (p0 != null) {
            Get.bottomSheet(
              BottomsheetWidget(
                asset: AppAsset.imgFaceSad,
                title: AppStrings.oopsTerjadiKesalahan,
                message: p0.message.toString(),
              ),
            );
          }
        }),
      ];
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
    return Scaffold(
      appBar: AppBar(),
      body: Observer(
        builder: (context) => SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Selamat Datang',
                style: TextStyle(fontSize: 30.sp),
              ),
              16.verticalSpace,
              Text(
                'Yuk, buat akun sekarang agar kita tetap nyambung!!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp),
              ),
              34.verticalSpace,
              TextfieldWidget(
                label: 'Nama',
                hintText: 'Masukan Nama',
                textInputType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onChanged: store.validateName,
                errorText: store.error.name,
              ),
              20.verticalSpace,
              TextfieldWidget(
                label: 'Email',
                hintText: 'Masukan Email',
                textInputType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: store.validateEmail,
                errorText: store.error.email,
              ),
              20.verticalSpace,
              TextfieldPasswordWidget.create(
                onValidPassword: (password) {
                  store.password = password;
                },
              ),
              50.verticalSpace,
              ButtonWidget(
                onPressed: !store.isValid
                    ? null
                    : () => store.register(onSuccessRegister: () async {
                          await Future.delayed(Duration(microseconds: 200));
                          Get.bottomSheet(
                            isDismissible: false,
                            isScrollControlled: false,
                            BottomsheetWidget(
                              asset: AppAsset.imgFaceWink,
                              restricBackNative: true,
                              title: 'Horee!! Registrasi Berhasil',
                              message: 'Yuk, verifikasi email kamu agar bisa mengakses semua fitur kami',
                              buttonText: 'Verifikasi Sekarang',
                              onButtonPressed: () {
                                final email = store.email;

                                if (email == null) return;
                                Get.toNamed(
                                  AppRouteName.VERIFY_SCREEN,
                                  arguments: VerifyArgument(email: email),
                                );
                              },
                            ),
                          );
                        }),
                title: 'Daftar',
              ),
              48.verticalSpace,
              Text.rich(
                TextSpan(
                  text: 'Sudah punya akun? ', // Default style applied to this segment
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Masuk',
                      recognizer: TapGestureRecognizer()..onTap = () => Get.offAndToNamed(AppRouteName.LOGIN_SCREEN),
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColor.primaryColor,
                        fontWeight: FontWeight.bold, // Specific style for "bold"
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ).paddingAll(20.r),
        ),
      ),
    );
  }
}
