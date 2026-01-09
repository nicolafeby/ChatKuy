import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:flutter/material.dart';

class AppRoute {
  static Map<String, Widget Function(BuildContext)> getMapRouteScreen(BuildContext context) {
    return {
      AppRouteName.LOGIN_SCREEN: (_) => LoginScreen(),
      AppRouteName.REGISTER_SCREEN: (_) => RegisterScreen(),
      AppRouteName.BASE_SCREEN: (_) => BaseScreen(),
      AppRouteName.VERIFY_SCREEN: (_) => VerifyScreen(),
    };
  }
}
