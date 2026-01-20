import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

mixin BaseLayout {
  void showLoading({String? text}) {
    dismissLoading();
    Get.dialog(const LoadingDialog(), barrierDismissible: false);
  }

  void dismissLoading() {
    Get.until((route) => Get.isDialogOpen == null || Get.isDialogOpen == false);
  }

  void dismissBottomsheet() {
    Get.until((route) => Get.isBottomSheetOpen == null || Get.isBottomSheetOpen == false);
  }

  void showSnackbar({
    String? title,
    String? message,
  }) {
    if (Get.isSnackbarOpen) return;

    final safeMessage = (message != null && message.isNotEmpty) ? message : 'Terjadi kesalahan';

    Get.showSnackbar(
      GetSnackBar(
        title: title ?? '',
        message: safeMessage,
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  void showComingSoonSnackbar() {
    showSnackbar(
      title: 'Tunggu, yaa...',
      message: 'Futur ini akan segera kami luncurkan',
    );
  }
}

class LoadingDialog extends StatelessWidget {
  final bool enableBackButton;
  final String? text;

  const LoadingDialog({
    this.enableBackButton = false,
    this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: enableBackButton,
      child: Dialog(
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(
                height: 10,
              ),
              Text(
                text ?? 'Loading',
                style: TextStyle(fontSize: 14.sp),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}
