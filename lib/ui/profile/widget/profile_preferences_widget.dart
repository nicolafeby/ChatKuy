import 'package:chatkuy/core/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePreferencesWidget extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final String title;
  const ProfilePreferencesWidget({
    super.key,
    required this.icon,
    required this.onTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(color: AppColor.whiteBlue, shape: BoxShape.circle),
            child: Container(
              height: 40.r,
              width: 40.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.primaryColor.withOpacity(0.8),
              ),
              child: icon,
            ),
          ),
        ),
        8.verticalSpace,
        Text(
          title,
          style: TextStyle(fontSize: 16.sp),
        )
      ],
    );
  }
}
