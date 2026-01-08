import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class FailedBottomsheet extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  const FailedBottomsheet({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Oke',
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Image.asset(AppAsset.imgFaceSad, height: 100.r),
          32.verticalSpace,
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
          ButtonWidget(onPressed: () => onButtonPressed ?? Get.back(), title: buttonText!)
        ],
      ),
    );
  }
}
