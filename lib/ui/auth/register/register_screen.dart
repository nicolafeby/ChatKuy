import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_password_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_widget.dart';
import 'package:chatkuy/stores/auth/register/register_store.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  RegisterStore store = RegisterStore();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Observer(
        builder: (context) => SingleChildScrollView(
          child: Column(
            children: [
              // Image.asset(AppAsset.imgFaceWink, height: 150.r),
              // 32.verticalSpace,
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
                label: 'Email',
                hintText: 'Masukan Email',
                textInputType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: store.validateEmail,
                errorText: store.errorEmail,
              ),
              20.verticalSpace,
              TextfieldPasswordWidget.create(
                onValidPassword: (password) {
                  store.password = password;
                },
              ),
              50.verticalSpace,
              ButtonWidget(
                onPressed: !store.isValid ? null : () {},
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
