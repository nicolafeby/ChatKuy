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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      leading: leading,
      actions: action,
      titleSpacing: 0,
      bottom: bottom,
      backgroundColor: isDark ? const Color(0xFF111B21) : Colors.white,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      surfaceTintColor: isDark ? const Color(0xFF111B21) : Colors.white,
      elevation: 0,
      title: Text(
        title,
        style: titleStyle ??
            TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }
}
