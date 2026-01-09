import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/stores/base/base_store.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:chatkuy/ui/friends/friend_list_sceeen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  BaseStore store = BaseStore();

  static const List<Widget> _widgetOptions = <Widget>[
    FriendListScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) => Scaffold(
        body: _widgetOptions.elementAt(store.selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          enableFeedback: false,
          selectedItemColor: AppColor.primaryColor,
          showSelectedLabels: true,
          currentIndex: store.selectedIndex,
          onTap: store.onTapItem,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Teman'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Percakapan'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
