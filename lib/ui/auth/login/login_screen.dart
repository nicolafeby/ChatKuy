import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_password_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_widget.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/auth/login/login_store.dart';
import 'package:chatkuy/stores/auth/register/register_store.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with BaseLayout {
  LoginStore store = LoginStore(
    service: getIt<AuthRepository>(),
    storageService: getIt<SecureStorageRepository>(),
  );

  RegisterStore registerStore = RegisterStore(
    service: getIt<AuthRepository>(),
    storageService: getIt<SecureStorageRepository>(),
  );

  List<ReactionDisposer> _reaction = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reaction = [
        reaction((p0) => store.loginFuture?.status, (p0) {
          if (p0 == FutureStatus.pending) {
            showLoading();
          } else {
            dismissLoading();
          }
        }),
        reaction((p0) => store.error.general, (p0) {
          if (p0 == null) return;
          if (p0.code.contains(AppStrings.emailNotVerified)) {
            Get.bottomSheet(
              BottomsheetWidget(
                title: AppStrings.oopsTerjadiKesalahan,
                asset: AppAsset.imgFaceSad,
                message: p0.message.toString(),
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
          } else {
            Get.bottomSheet(
              BottomsheetWidget(
                title: AppStrings.oopsTerjadiKesalahan,
                asset: AppAsset.imgFaceSad,
                message: p0.message.toString(),
              ),
            );
          }
        }),
        reaction((p0) => registerStore.resendEmailFuture?.status, (p0) {
          if (p0 == FutureStatus.pending) {
            showLoading();
          } else {
            dismissLoading();
          }
        }),
        reaction((p0) => registerStore.error.general, (p0) {
          if (p0 == null) return;
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
      appBar: AppBar(toolbarHeight: 0),
      body: Observer(
        builder: (context) => SingleChildScrollView(
          child: Column(
            children: [
              8.verticalSpace,
              Image.asset(AppAsset.imgFaceSmile, height: 150.r),
              32.verticalSpace,
              Text(
                'Welcome Back',
                style: TextStyle(fontSize: 30.sp),
              ),
              50.verticalSpace,
              TextfieldWidget(
                label: 'Email',
                hintText: 'Masukan Email',
                textInputType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: store.validateEmail,
                errorText: store.error.email,
              ),
              20.verticalSpace,
              TextfieldPasswordWidget.verify(
                onValidPassword: (password) {
                  store.password = password;
                },
              ),
              8.verticalSpace,
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  child: Text(
                    'Lupa Password?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              50.verticalSpace,
              ButtonWidget(
                onPressed: !store.isValid
                    ? null
                    : () => store.login(
                          onSuccess: () async {
                            await Future.delayed(Duration(milliseconds: 500));
                            Get.toNamed(AppRouteName.BASE_SCREEN);
                          },
                        ),
                title: 'Masuk',
              ),
              48.verticalSpace,
              Text.rich(
                TextSpan(
                  text: 'Tidak punya akun? ',
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Daftar',
                      recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(AppRouteName.REGISTER_SCREEN),
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColor.primaryColor,
                        fontWeight: FontWeight.bold,
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
