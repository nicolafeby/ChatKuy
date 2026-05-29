import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/formatter.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_password_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_widget.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/auth/register/register_store.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    storageService: getIt<SecureStorageRepository>(),
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
              isScrollControlled: true,
              BottomsheetWidget(
                asset: AppAsset.imgFaceSad,
                title: AppStrings.oopsTerjadiKesalahan,
                message: p0.message.toString(),
                errorTicketId: AppErrorLogger.latestErrorTicketId,
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
                AppTranslationKey.welcome.tr,
                style: TextStyle(fontSize: 30.sp),
              ),
              16.verticalSpace,
              Text(
                AppTranslationKey.registerSubtitle.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp),
              ),
              34.verticalSpace,
              TextfieldWidget(
                label: AppTranslationKey.name.tr,
                hintText: AppTranslationKey.enterName.tr,
                textInputType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onChanged: store.validateName,
                errorText: store.error.name,
              ),
              20.verticalSpace,
              TextfieldWidget(
                label: AppTranslationKey.username.tr,
                hintText: AppTranslationKey.enterUsername.tr,
                textInputType: TextInputType.name,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(AppFormatter.usernameRegex)
                ],
                onChanged: store.validateUsername,
                errorText: store.error.username,
              ),
              20.verticalSpace,
              TextfieldWidget(
                label: AppTranslationKey.email.tr,
                hintText: AppTranslationKey.enterEmail.tr,
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
                              title:
                                  AppTranslationKey.registrationSuccessTitle.tr,
                              message: AppTranslationKey
                                  .verifyEmailToAccessFeatures.tr,
                              buttonText: AppTranslationKey.verifyNow.tr,
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
                title: AppTranslationKey.register.tr,
              ),
              48.verticalSpace,
              Text.rich(
                TextSpan(
                  text: AppTranslationKey.alreadyHaveAccount.tr,
                  children: <InlineSpan>[
                    TextSpan(
                      text: AppTranslationKey.login.tr,
                      recognizer: TapGestureRecognizer()
                        ..onTap =
                            () => Get.offAndToNamed(AppRouteName.LOGIN_SCREEN),
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColor.primaryColor,
                        fontWeight:
                            FontWeight.bold, // Specific style for "bold"
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
