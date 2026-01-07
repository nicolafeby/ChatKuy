import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/stores/password_field/password_field_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class TextfieldPasswordWidget extends StatefulWidget {
  const TextfieldPasswordWidget({super.key});

  @override
  State<TextfieldPasswordWidget> createState() => _TextfieldPasswordWidgetState();
}

class _TextfieldPasswordWidgetState extends State<TextfieldPasswordWidget> {
  PasswordFieldStore store = PasswordFieldStore();

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => TextField(
        onChanged: (value) => store.setPassword(value),
        obscureText: !store.isPasswordVisible,
        cursorColor: AppColor.primaryColor,
        decoration: InputDecoration(
          floatingLabelStyle: TextStyle(
            color: store.passwordError != null ? Colors.red : AppColor.primaryColor,
          ),
          labelText: 'Password',
          errorText: store.passwordError,
          prefixIcon: Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(store.isPasswordVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: store.toggleVisibility,
          ),
        ),
      ),
    );
  }
}
