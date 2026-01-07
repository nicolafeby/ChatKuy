import 'package:chatkuy/core/constants/color.dart';
import 'package:flutter/material.dart';

class TextfieldWidget extends StatelessWidget {
  final String? hintText;
  final String label;
  final TextInputAction? textInputAction;
  final TextInputType? textInputType;
  final Function(String value)? onChanged;
  final String? errorText;
  const TextfieldWidget({
    super.key,
    this.hintText,
    required this.label,
    this.textInputAction,
    this.textInputType,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      textInputAction: textInputAction,
      keyboardType: textInputType,
      cursorColor: AppColor.primaryColor,
      
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        floatingLabelStyle: TextStyle(
            color: errorText != null ? Colors.red : AppColor.primaryColor,
          ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintText: hintText,
      ),
    );
  }
}
