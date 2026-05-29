import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/navigation/initial_route_argument.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/data/models/app_update_info.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateScreenArgument {
  const AppUpdateScreenArgument({
    required this.updateInfo,
    required this.nextRouteName,
  });

  final AppUpdateInfo updateInfo;
  final String nextRouteName;
}

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  AppUpdateScreenArgument? _argument;

  AppUpdateInfo get _updateInfo => _argument!.updateInfo;

  @override
  void initState() {
    super.initState();
    _argument = Get.arguments as AppUpdateScreenArgument? ??
        InitialRouteArgument.takeAppUpdate();

    if (_argument == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRouteName.BASE_SCREEN);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_argument == null) return const SizedBox.shrink();

    final isRequired = _updateInfo.isUpdateRequired;

    return PopScope(
      canPop: !isRequired,
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 0),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                const Spacer(),
                Image.asset(
                  isRequired ? AppAsset.imgFaceSad : AppAsset.imgFaceWink,
                  height: 132.r,
                ),
                28.verticalSpace,
                Text(
                  isRequired
                      ? AppTranslationKey.updateRequired.tr
                      : AppTranslationKey.updateAvailable.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                12.verticalSpace,
                Text(
                  isRequired
                      ? AppTranslationKey.updateRequiredMessage.tr
                      : AppTranslationKey.updateAvailableMessage.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
                28.verticalSpace,
                _RequirementBox(updateInfo: _updateInfo),
                const Spacer(),
                ButtonWidget(
                  title: AppTranslationKey.openAppTester.tr,
                  onPressed: _openAppTester,
                ),
                if (!isRequired) ...[
                  12.verticalSpace,
                  TextButton(
                    onPressed: () => Get.offAllNamed(_argument!.nextRouteName),
                    child: Text(
                      AppTranslationKey.later.tr,
                      style: TextStyle(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAppTester() async {
    final uri = Uri.tryParse(_updateInfo.appTesterUrl);
    if (uri == null) {
      Get.snackbar(AppTranslationKey.failedOpenAppTester.tr,
          AppTranslationKey.invalidAppTesterUrl.tr);
      return;
    }

    final isLaunched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!isLaunched) {
      Get.snackbar(AppTranslationKey.failedOpenAppTester.tr,
          AppTranslationKey.tryAgainLater.tr);
    }
  }
}

class _RequirementBox extends StatelessWidget {
  const _RequirementBox({required this.updateInfo});

  final AppUpdateInfo updateInfo;

  @override
  Widget build(BuildContext context) {
    final versionTarget = updateInfo.isUpdateRequired
        ? updateInfo.minimumRequiredVersion
        : updateInfo.recommendedVersion;
    final buildTarget = updateInfo.isUpdateRequired
        ? updateInfo.minimumRequiredBuildNumber
        : updateInfo.recommendedBuildNumber;
    final versionLabel = updateInfo.isUpdateRequired
        ? AppTranslationKey.minimumAppVersion.tr
        : AppTranslationKey.recommendedAppVersion.tr;
    final buildLabel = updateInfo.isUpdateRequired
        ? AppTranslationKey.minimumBuildNumber.tr
        : AppTranslationKey.recommendedBuildNumber.tr;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.whiteBlue,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            _VersionRow(
              label: AppTranslationKey.yourVersion.tr,
              value:
                  '${updateInfo.currentVersion}+${updateInfo.currentBuildNumberText}',
            ),
            if (versionTarget.trim().isNotEmpty) ...[
              12.verticalSpace,
              _VersionRow(
                label: versionLabel,
                value: versionTarget,
              ),
            ],
            if (buildTarget > 0) ...[
              12.verticalSpace,
              _VersionRow(
                label: buildLabel,
                value: buildTarget.toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13.sp,
            ),
          ),
        ),
        12.horizontalSpace,
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
