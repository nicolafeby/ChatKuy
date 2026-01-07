import 'package:chatkuy/core/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ButtonWidget extends StatelessWidget {
  final Function()? onPressed;
  final String title;
  const ButtonWidget({super.key, required this.onPressed, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primaryColor,
          elevation: 0.0, // Set the base elevation to zero
          shadowColor: Colors.transparent, // Make the shadow transparent
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
      ),
    );
  }
}
