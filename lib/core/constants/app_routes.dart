import 'package:chatkuy/ui/_ui.dart';
import 'package:flutter/material.dart';

abstract class AppRouteName {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const chatList = '/chat-list';
  static const chatRoom = '/chat-room';
  static const profile = '/profile';
}

class AppRoute {
  static Map<String, Widget Function(BuildContext)> getMapRouteScreen(BuildContext context) {
    return {AppRouteName.login: (_) => LoginScreen(), AppRouteName.register: (_) => RegisterScreen()};
  }
}
