import 'package:chatkuy/core/utils/extension/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final String? base64Image;
  final double size;
  const ProfileAvatarWidget({super.key, required this.base64Image, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.r,
      width: size.r,
      child: CircleAvatar(
        radius: 24.r,
        backgroundImage: base64Image != null ? MemoryImage(base64Image!.base64GzipToBytes()) : null,
        child: base64Image == null ? Icon(Icons.person, size: (size / 2).r) : null,
      ),
    );
  }
}
