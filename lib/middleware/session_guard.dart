import 'package:chatkuy/app_context.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/routes/route_middleware.dart';

class SessionGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final session = AppContext.sessionStore;

    if (!session.isReady) return null;

    if (!session.isLoggedIn && route != AppRouteName.LOGIN_SCREEN) {
      return const RouteSettings(name: AppRouteName.LOGIN_SCREEN);
    }

    if (session.isLoggedIn && route == AppRouteName.LOGIN_SCREEN) {
      return const RouteSettings(name: AppRouteName.BASE_SCREEN);
    }

    return null;
  }
}
