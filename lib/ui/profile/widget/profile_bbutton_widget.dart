import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileButtonWidget extends StatelessWidget {
  final Widget title;
  final Widget leading;
  final VoidCallback onTap;
  const ProfileButtonWidget({super.key, required this.title, required this.leading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 0,
      contentPadding: EdgeInsets.symmetric(horizontal: 4).r,
      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
      leading: leading,
      title: title,
      onTap: onTap.call,
      // trailing: Icon(
      //   Icons.arrow_forward_ios_rounded,
      //   size: 20.r,
      //   color: Colors.grey,
      // ),
    );
  }
}
