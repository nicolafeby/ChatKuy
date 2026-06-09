import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatUnreadSeparator extends StatelessWidget with BaseLayout {
  final String label;

  const ChatUnreadSeparator({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = isDarkModeOf(context);
    final lineColor = AppColor.primaryColor.withValues(
      alpha: isDarkMode ? 0.55 : 0.35,
    );
    final labelBackground = isDarkMode
        ? AppColor.primaryColor.withValues(alpha: 0.24)
        : AppColor.primaryColor.withValues(alpha: 0.12);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, thickness: 1, color: lineColor)),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: labelBackground,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: AppColor.primaryColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Divider(height: 1, thickness: 1, color: lineColor)),
        ],
      ),
    );
  }
}
