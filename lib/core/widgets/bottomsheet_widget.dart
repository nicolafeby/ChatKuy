import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class BottomsheetWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final String? asset;
  final bool? restricBackNative;
  const BottomsheetWidget({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Oke',
    this.onButtonPressed,
    this.asset,
    this.restricBackNative = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !restricBackNative!,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            16.verticalSpace,
            Visibility(
              visible: asset == null ? false : true,
              child: Image.asset(asset ?? '', height: 100.r).paddingOnly(bottom: 32.h),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            16.verticalSpace,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w300),
            ),
            32.verticalSpace,
            ButtonWidget(onPressed: onButtonPressed ?? () => Get.back(), title: buttonText!)
          ],
        ),
      ),
    );
  }
}
