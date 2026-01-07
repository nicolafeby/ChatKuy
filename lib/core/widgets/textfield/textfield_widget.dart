import 'package:chatkuy/core/constants/color.dart';
import 'package:flutter/material.dart';

class TextfieldWidget extends StatelessWidget {
  final String? hintText;
  final String label;
  final TextInputAction? textInputAction;
  final TextInputType? textInputType;
  const TextfieldWidget({
    super.key,
    this.hintText,
    required this.label,
    this.textInputAction,
    this.textInputType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textInputAction: textInputAction,
      keyboardType: textInputType,
      cursorColor: AppColor.primaryColor,
      decoration: InputDecoration(
        labelText: label,

        floatingLabelStyle: TextStyle(color: AppColor.primaryColor),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintText: hintText,
      ),
    );
  }
}
