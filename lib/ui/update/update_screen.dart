import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/navigation/initial_route_argument.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/data/models/app_update_info.dart';
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
    _argument = Get.arguments as AppUpdateScreenArgument? ?? InitialRouteArgument.takeAppUpdate();

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
                  isRequired ? 'Update Diperlukan' : 'Update Tersedia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                12.verticalSpace,
                Text(
                  isRequired
                      ? 'Versi ChatKuy yang kamu pakai sudah berada di bawah minimum yang didukung.'
                      : 'Ada versi ChatKuy yang lebih baru. Kamu bisa update sekarang atau lanjut dulu.',
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
                  title: 'Buka App Tester',
                  onPressed: _openAppTester,
                ),
                if (!isRequired) ...[
                  12.verticalSpace,
                  TextButton(
                    onPressed: () => Get.offAllNamed(_argument!.nextRouteName),
                    child: Text(
                      'Nanti saja',
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
      Get.snackbar('Gagal membuka App Tester', 'URL App Tester tidak valid');
      return;
    }

    final isLaunched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!isLaunched) {
      Get.snackbar('Gagal membuka App Tester', 'Silakan coba lagi beberapa saat lagi');
    }
  }
}

class _RequirementBox extends StatelessWidget {
  const _RequirementBox({required this.updateInfo});

  final AppUpdateInfo updateInfo;

  @override
  Widget build(BuildContext context) {
    final versionTarget =
        updateInfo.isUpdateRequired ? updateInfo.minimumRequiredVersion : updateInfo.recommendedVersion;
    final buildTarget =
        updateInfo.isUpdateRequired ? updateInfo.minimumRequiredBuildNumber : updateInfo.recommendedBuildNumber;
    final versionLabel = updateInfo.isUpdateRequired ? 'Minimal app version' : 'Rekomendasi app version';
    final buildLabel = updateInfo.isUpdateRequired ? 'Minimal build number' : 'Rekomendasi build number';

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
              label: 'Versi kamu',
              value: '${updateInfo.currentVersion}+${updateInfo.currentBuildNumberText}',
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
