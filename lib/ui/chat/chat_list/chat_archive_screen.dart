import 'package:chatkuy/ui/chat/chat_list/chat_list_screen.dart';
import 'package:flutter/material.dart';

class ChatArchiveScreen extends StatelessWidget {
  const ChatArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatListScreen(archivedOnly: true);
  }
}
