import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/stores/password_field/password_field_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum PasswordType { create, verify }

class TextfieldPasswordWidget extends StatefulWidget {
  final PasswordType passwordType;
  final Function(String? password) onValidPassword;
  const TextfieldPasswordWidget._({super.key, required this.passwordType, required this.onValidPassword});

  factory TextfieldPasswordWidget.create({Key? key, required Function(String? password) onValidPassword}) {
    return TextfieldPasswordWidget._(
      key: key,
      passwordType: PasswordType.create,
      onValidPassword: onValidPassword,
    );
  }

  factory TextfieldPasswordWidget.verify({Key? key, required Function(String? password) onValidPassword}) {
    return TextfieldPasswordWidget._(
      key: key,
      passwordType: PasswordType.verify,
      onValidPassword: onValidPassword,
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
