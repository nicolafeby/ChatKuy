import 'package:chatkuy/core/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextfieldWidget extends StatelessWidget {
  final String? hintText;
  final String label;
  final TextInputAction? textInputAction;
  final TextInputType? textInputType;
  final Function(String value)? onChanged;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final FloatingLabelBehavior? floatingLabelBehavior;
  const TextfieldWidget({
    super.key,
    this.hintText,
    required this.label,
    this.textInputAction,
    this.textInputType,
    this.onChanged,
    this.errorText,
    this.inputFormatters,
    this.floatingLabelBehavior,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      onChanged: onChanged,
      textInputAction: textInputAction,
      keyboardType: textInputType,
      cursorColor: AppColor.primaryColor,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        errorStyle: TextStyle(color: colorScheme.error),
        floatingLabelStyle: TextStyle(
          color: errorText != null ? colorScheme.error : AppColor.primaryColor,
        ),
        floatingLabelBehavior:
            floatingLabelBehavior ?? FloatingLabelBehavior.auto,
        hintText: hintText,
      ),
    );
  }
}
