import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_password_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_widget.dart';
import 'package:chatkuy/stores/login/login_store.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/widget_extensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginStore store = LoginStore();
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
                errorText: store.errorEmail,
              ),
              20.verticalSpace,
              TextfieldPasswordWidget(),
              8.verticalSpace,
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  child: Text(
                    'Lupa Password?',
                    style: TextStyle(
                      fontSize: 16.sp,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              50.verticalSpace,
              ButtonWidget(
                onPressed: () {},
                title: 'Masuk',
              ),
              48.verticalSpace,
              Text.rich(
                TextSpan(
                  text: 'Tidak punya akun? ', // Default style applied to this segment
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Masuk',
                      recognizer: TapGestureRecognizer()..onTap = () {},
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
