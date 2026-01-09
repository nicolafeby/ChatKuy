import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/middleware/session_guard.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:get/get_navigation/get_navigation.dart';

class AppRoute {
  static final pages = [
    GetPage(
      name: AppRouteName.LOGIN_SCREEN,
      page: () => LoginScreen(),
    ),
    GetPage(
      name: AppRouteName.REGISTER_SCREEN,
      page: () => RegisterScreen(),
    ),
    GetPage(
      name: AppRouteName.VERIFY_SCREEN,
      page: () => VerifyScreen(),
    ),
    GetPage(
      name: AppRouteName.BASE_SCREEN,
      page: () => BaseScreen(),
      middlewares: [SessionGuard()],
    ),
  ];
}
