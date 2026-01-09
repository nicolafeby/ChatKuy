import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/stores/base/base_store.dart';
import 'package:chatkuy/ui/chat/chat_list/chat_list_screen.dart';
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
    Center(child: Text('Home Page', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
    ChatListScreen(),
    // Center(child: Text('Profile Page', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
    Center(child: Text('Settings Page', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
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
            BottomNavigationBarItem(icon: Icon(Icons.people), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
            // BottomNavigationBarItem(icon: Icon(Icons.profile)),
          ],
        ),
      ),
    );
  }
}
