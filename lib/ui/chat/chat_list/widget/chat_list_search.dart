import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';

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
          ? _buildTextField(context)
          : ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller!,
              builder: (context, value, _) => _buildTextField(context),
            ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      cursorHeight: 16.h,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? const Color(0xFF202C33) : const Color(0xFFF0F2F5),
        prefixIcon: const Icon(Icons.search),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIcon: controller?.text.isEmpty == false
            ? IconButton(
                tooltip: AppTranslationKey.clearSearch.tr,
                onPressed: onClear,
                icon: Icon(Icons.close, size: 18.r),
              )
            : null,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(50.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(50.r),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintText: AppTranslationKey.searchChats.tr,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
      ),
    );
  }
}
