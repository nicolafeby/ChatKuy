import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatListSearchWidget extends StatelessWidget {
  const ChatListSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: TextField(
        cursorHeight: 16.h,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          prefixIconColor: Colors.grey,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(50.r),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(50.r),
          ),
          // floatingLabelStyle: TextStyle(

          //     color: errorText != null ? Colors.red : AppColor.primaryColor,
          //     ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintText: 'Cari percakapan',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
        ),
      ),
    );
  }
}
