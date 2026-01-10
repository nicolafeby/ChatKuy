import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'chat_room_store.g.dart';

class ChatRoomStore = _ChatRoomStore with _$ChatRoomStore;

abstract class _ChatRoomStore with Store {
  _ChatRoomStore({required this.chatRepository});

  final ChatRepository chatRepository;

  late TextEditingController messageController;

  @observable
  bool isSending = false;

  @observable
  ObservableStream<List<ChatMessageModel>>? messages;

  @observable
  String? roomId;

  @action
  void init({
    required String roomId,
    required String currentUid,
  }) {
    messageController = TextEditingController();

    this.roomId = roomId;

    messages = chatRepository.watchMessages(roomId: roomId).asObservable();

    // reset unread count ketika masuk room
    chatRepository.markAsRead(
      roomId: roomId,
      uid: currentUid,
    );
  }

  @action
  Future<void> sendMessage(String text) async {
    if (roomId == null || text.trim().isEmpty) return;

    await chatRepository.sendMessage(
      roomId: roomId!,
      text: text.trim(),
    );
  }

  @action
  void dispose() {
    roomId = null;
    messages = null;
    messageController.dispose();
  }
}
