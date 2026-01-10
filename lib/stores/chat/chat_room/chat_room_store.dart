import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'chat_room_store.g.dart';

class ChatRoomStore = _ChatRoomStore with _$ChatRoomStore;

abstract class _ChatRoomStore with Store {
  _ChatRoomStore() {
    init();
  }

  late TextEditingController messageController;

  @observable
  ObservableList<String> messages = ObservableList.of([]);

  @observable
  bool isSending = false;

  void init() {
    messageController = TextEditingController();
  }

   @action
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    isSending = true;

    // simulasi delay / kirim ke server
    await Future.delayed(const Duration(milliseconds: 150));

    messages.insert(0, text);
    messageController.clear();

    isSending = false;
  }

  void dispose() {
    messageController.dispose();
  }
}
