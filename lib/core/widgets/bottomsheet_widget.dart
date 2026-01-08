import 'package:chatkuy/core/constants/asset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FailedBottomsheet extends StatelessWidget {
  final String title;
  final String message;
  const FailedBottomsheet({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppAsset.imgFaceSad, height: 100.r),
          16.verticalSpace,
          Text(
            title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          16.verticalSpace,
          Text(
            message,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
}
