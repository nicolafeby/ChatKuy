import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/middleware/session_guard.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:chatkuy/ui/add_friend/add_friend_screem.dart';
import 'package:chatkuy/ui/friend_request_list/friend_request_list_screen.dart';
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
    GetPage(
      name: AppRouteName.CHAT_ROOM_SCREEN,
      page: () => ChatRoomScreen(),
    ),
    GetPage(
      name: AppRouteName.ADD_FRIEND_SCREEN,
      page: () => AddFriendScreen(),
    ),
    GetPage(
      name: AppRouteName.FRIEND_REQUEST_LIST_SCREEN,
      page: () => FriendRequestScreen(),
    )
  ];
}
