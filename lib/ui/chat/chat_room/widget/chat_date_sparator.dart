import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatDateSeparator extends StatelessWidget with BaseLayout {
  final String label;

  const ChatDateSeparator({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = isDarkModeOf(context);
    final backgroundColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.15);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ).r,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
