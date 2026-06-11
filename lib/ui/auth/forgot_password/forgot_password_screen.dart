import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_widget.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/auth/forgot_password/forgot_password_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with BaseLayout {
  final ForgotPasswordStore store = ForgotPasswordStore(
    service: getIt<AuthRepository>(),
  );

  List<ReactionDisposer> _reaction = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reaction = [
        reaction((p0) => store.resetPasswordFuture?.status, (p0) {
          if (p0 == FutureStatus.pending) {
            showLoading();
          } else {
            dismissLoading();
          }

          if (p0 == FutureStatus.fulfilled) {
            _showResetLinkSentBottomSheet();
          }
        }),
        reaction((p0) => store.error.general, (p0) {
          if (p0 == null) return;

          Get.bottomSheet(
            isScrollControlled: true,
            BottomsheetWidget(
              title: AppStrings.oopsTerjadiKesalahan,
              asset: AppAsset.imgFaceSad,
              message: p0.message.toString(),
              errorTicketId: AppErrorLogger.latestErrorTicketId,
            ),
          );
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
        builder: (_) => SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(AppAsset.imgFaceWink, height: 140.r),
              32.verticalSpace,
              Text(
                AppTranslationKey.resetPassword.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30.sp),
              ),
              16.verticalSpace,
              Text(
                AppTranslationKey.forgotPasswordInstruction.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
              34.verticalSpace,
              TextfieldWidget(
                label: AppTranslationKey.usernameOrEmail.tr,
                hintText: AppTranslationKey.enterUsernameOrEmail.tr,
                textInputType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onChanged: store.validateIdentifier,
                errorText: store.error.identifier,
              ),
              50.verticalSpace,
              ButtonWidget(
                onPressed: !store.isValid
                    ? null
                    : () => store.sendResetLink(onSuccess: () {}),
                title: AppTranslationKey.sendResetLink.tr,
              ),
            ],
          ).paddingAll(20.r),
        ),
      ),
    );
  }

  void _showResetLinkSentBottomSheet() {
    Get.bottomSheet(
      isDismissible: false,
      isScrollControlled: true,
      BottomsheetWidget(
        asset: AppAsset.imgFaceWink,
        restricBackNative: true,
        title: AppTranslationKey.resetLinkSentTitle.tr,
        message: AppTranslationKey.resetLinkSentMessage.tr,
        buttonText: AppTranslationKey.backToLogin.tr,
        onButtonPressed: () => Get.offAllNamed(AppRouteName.LOGIN_SCREEN),
      ),
    );
  }
}
