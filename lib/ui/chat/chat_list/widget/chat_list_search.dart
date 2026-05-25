import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatListSearchWidget extends StatelessWidget {
  const ChatListSearchWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: controller == null
          ? _buildTextField()
          : ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller!,
              builder: (context, value, _) => _buildTextField(),
            ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: controller,
      cursorHeight: 16.h,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search),
        prefixIconColor: Colors.grey,
        suffixIcon: controller?.text.isEmpty == false
            ? IconButton(
                tooltip: 'Bersihkan pencarian',
                onPressed: onClear,
                icon: Icon(Icons.close, size: 18.r),
              )
            : null,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(50.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(50.r),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintText: 'Cari percakapan',
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
      ),
    );
  }
}
