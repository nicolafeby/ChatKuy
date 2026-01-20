import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/stores/password_field/password_field_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum PasswordType { create, verify }

class TextfieldPasswordWidget extends StatefulWidget {
  final PasswordType passwordType;
  final Function(String? password) onValidPassword;
  final String? label;
  final String? hintText;
  const TextfieldPasswordWidget._({
    super.key,
    required this.passwordType,
    required this.onValidPassword,
    this.hintText,
    this.label,
  });

  factory TextfieldPasswordWidget.create({Key? key, required Function(String? password) onValidPassword}) {
    return TextfieldPasswordWidget._(
      key: key,
      passwordType: PasswordType.create,
      onValidPassword: onValidPassword,
    );
  }

  factory TextfieldPasswordWidget.verify({
    Key? key,
    required Function(String? password) onValidPassword,
    String? label,
    String? hintText,
  }) {
    return TextfieldPasswordWidget._(
      key: key,
      passwordType: PasswordType.verify,
      onValidPassword: onValidPassword,
      hintText: hintText,
      label: label,
    );
  }

  @override
  State<TextfieldPasswordWidget> createState() => _TextfieldPasswordWidgetState();
}

class _TextfieldPasswordWidgetState extends State<TextfieldPasswordWidget> {
  PasswordFieldStore store = PasswordFieldStore();

  @override
  Widget build(BuildContext context) {
    if (widget.passwordType == PasswordType.verify) {
      return Observer(
        builder: (_) => TextField(
          onChanged: (value) {
            store.setPassword(value);

            if (store.isVerifyPasswordValid) {
              widget.onValidPassword(value);
            } else {
              widget.onValidPassword(null);
            }
          },
          obscureText: !store.isPasswordVisible,
          cursorColor: AppColor.primaryColor,
          decoration: InputDecoration(
            floatingLabelStyle: TextStyle(
              color: store.passwordError != null ? Colors.red : AppColor.primaryColor,
            ),
            labelText: widget.label ?? 'Password',
            hintText: widget.hintText ?? 'Masukan password',
            errorText: store.passwordError,
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(store.isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: store.toggleVisibility,
            ),
          ),
        ),
      );
    } else {
      return Observer(
        builder: (context) => Column(
          children: [
            TextField(
              onChanged: (value) {
                store.setPassword(value);

                if (store.isCreatePasswordValid) {
                  widget.onValidPassword(store.password);
                } else {
                  widget.onValidPassword(null);
                }
              },
              obscureText: !store.isPasswordVisible,
              cursorColor: AppColor.primaryColor,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                floatingLabelStyle: TextStyle(
                  color: store.passwordError != null ? Colors.red : AppColor.primaryColor,
                ),
                labelText: 'Password',
                hintText: 'Masukan password',
                errorText: store.passwordError,
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(store.isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: store.toggleVisibility,
                ),
              ),
            ),
            20.verticalSpace,
            TextField(
              onChanged: (value) {
                store.setConfirmPassword(value);
                // store.setPassword(store.password);
                if (store.isCreatePasswordValid) {
                  widget.onValidPassword(value);
                } else {
                  widget.onValidPassword(null);
                }
              },
              obscureText: !store.isPasswordVisible,
              cursorColor: AppColor.primaryColor,
              decoration: InputDecoration(
                floatingLabelStyle: TextStyle(
                  color: store.confirmPasswordError != null ? Colors.red : AppColor.primaryColor,
                ),
                labelText: 'Konfirmasi Password',
                hintText: 'Masukan konfirmasi password',
                errorText: store.confirmPasswordError,
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(store.isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: store.toggleVisibility,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
