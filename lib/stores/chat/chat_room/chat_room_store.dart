import 'dart:async';

import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'chat_room_store.g.dart';

class ChatRoomStore = _ChatRoomStore with _$ChatRoomStore;

abstract class _ChatRoomStore with Store {
  _ChatRoomStore({
    required this.chatRepository,
    required this.userRepository,
  });

  final ChatRepository chatRepository;
  final UserRepository userRepository;

  late TextEditingController messageController;

  ObservableStream<List<ChatMessageModel>>? _serverMessages;
  ObservableStream<UserModel>? targetUser;
  ObservableStream<Map<String, bool>>? typing;

  @observable
  String? roomId;

  @observable
  String? currentUid;

  @computed
  List<ChatMessageModel> get messages {
    final list = _serverMessages?.value ?? [];

    // 🔥 AUTO DELIVERED + READ SYNC
    _syncMessageStatus(list);

    return list;
  }

  // -----------------------
  // INIT
  // -----------------------
  @action
  void init({
    required String roomId,
    required String currentUid,
    required String targetUid,
  }) {
    this.roomId = roomId;
    this.currentUid = currentUid;

    messageController = TextEditingController();

    _serverMessages = chatRepository.watchMessages(roomId: roomId).asObservable();

    targetUser = userRepository.watchUser(targetUid).asObservable();
    typing = chatRepository.watchTyping(roomId: roomId).asObservable();
  }

  // -----------------------
  // SEND MESSAGE
  // -----------------------
  @action
  Future<void> sendMessage(String text) async {
    if (roomId == null || text.trim().isEmpty) return;

    messageController.clear();

    await chatRepository.sendMessage(
      roomId: roomId!,
      text: text,
    );
  }

  // -----------------------
  // SYNC DELIVERED / READ
  // -----------------------
  void _syncMessageStatus(List<ChatMessageModel> messages) {
    if (roomId == null || currentUid == null) return;

    for (final message in messages) {
      // ❌ jangan proses pesan milik sendiri
      if (message.senderId == currentUid) continue;

      // ✓✓ delivered
      if (!message.deliveredTo.containsKey(currentUid)) {
        chatRepository.markDelivered(
          roomId: roomId!,
          messageId: message.id,
          uid: currentUid!,
        );
      }

      // ✓✓ read
      if (!message.readBy.containsKey(currentUid)) {
        chatRepository.markRead(
          roomId: roomId!,
          messageId: message.id,
          uid: currentUid!,
        );
      }
    }
  }

  // -----------------------
  // TYPING
  // -----------------------
  Timer? _typingTimer;

  @action
  void onTypingChanged(String text) {
    if (roomId == null || currentUid == null) return;

    chatRepository.setTyping(
      roomId: roomId!,
      uid: currentUid!,
      isTyping: text.isNotEmpty,
    );

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      chatRepository.setTyping(
        roomId: roomId!,
        uid: currentUid!,
        isTyping: false,
      );
    });
  }

  // -----------------------
  // DISPOSE
  // -----------------------
  @action
  void dispose() {
    if (roomId != null && currentUid != null) {
      chatRepository.setTyping(
        roomId: roomId!,
        uid: currentUid!,
        isTyping: false,
      );
    }

    _typingTimer?.cancel();
    roomId = null;
    _serverMessages = null;
    targetUser = null;
    messageController.dispose();
  }
}
