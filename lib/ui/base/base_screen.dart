import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/stores/base/base_store.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:chatkuy/ui/chat/call/call_history_screen.dart';
import 'package:chatkuy/ui/friends_list/friend_list_sceeen.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  BaseStore store = BaseStore();

  static final List<Widget> _widgetOptions = <Widget>[
    const FriendListScreen(),
    const ChatListScreen(),
    CallHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          SystemNavigator.pop();
        },
        child: Scaffold(
          body: IndexedStack(
            index: store.selectedIndex,
            children: _widgetOptions,
            //  _widgetOptions.elementAt(store.selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            enableFeedback: false,
            selectedItemColor: AppColor.primaryColor,
            showSelectedLabels: true,
            currentIndex: store.selectedIndex,
            onTap: store.onTapItem,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: AppTranslationKey.friends.tr),
              BottomNavigationBarItem(
                  icon: Icon(Icons.chat), label: AppTranslationKey.chats.tr),
              BottomNavigationBarItem(
                  icon: Icon(Icons.call), label: AppTranslationKey.calls.tr),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: AppTranslationKey.profile.tr),
            ],
          ),
        ),
      ),
    );
  }
}
