import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppbarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppbarWidget({
    super.key,
    required this.title,
    this.action,
    this.leading,
    this.titleStyle,
    this.bottom,
    this.appbarHeight,
  });

  final List<Widget>? action;
  final Widget? leading;
  final String title;
  final TextStyle? titleStyle;
  final PreferredSizeWidget? bottom;
  final double? appbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(appbarHeight ?? 56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      bottom: bottom,
      title: Text(
        title,
        style: titleStyle ?? TextStyle(fontSize: 18.sp),
      ),
    );
  }
}
