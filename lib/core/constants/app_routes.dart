// ignore_for_file: constant_identifier_names

import 'package:chatkuy/ui/_ui.dart';
import 'package:flutter/material.dart';

abstract class AppRouteName {
  static const splash = '/';
  static const LOGIN_SCREEN = '/login';
  static const REGISTER_SCREEN = '/register';
  static const chatList = '/chat-list';
  static const chatRoom = '/chat-room';
  static const profile = '/profile';
}

class AppRoute {
  static Map<String, Widget Function(BuildContext)> getMapRouteScreen(BuildContext context) {
    return {
      AppRouteName.LOGIN_SCREEN: (_) => LoginScreen(),
      AppRouteName.REGISTER_SCREEN: (_) => RegisterScreen(),
    };
  }
}
