import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'chat_room_store.g.dart';

class ChatRoomStore = _ChatRoomStore with _$ChatRoomStore;

abstract class _ChatRoomStore with Store {
  _ChatRoomStore({required this.chatRepository, required this.userRepository});

  final ChatRepository chatRepository;
  final UserRepository userRepository;

  late TextEditingController messageController;

  ObservableStream<List<ChatMessageModel>>? _serverMessages;
  ObservableStream<UserModel>? targetUser;

  @observable
  String? roomId;

  @observable
  String? currentUid;

  @computed
  List<ChatMessageModel> get messages {
    return _serverMessages?.value ?? [];
  }

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

    chatRepository.markAsRead(
      roomId: roomId,
      uid: currentUid,
    );
  }

  @action
  Future<void> sendMessage(String text) async {
    if (roomId == null || text.trim().isEmpty) return;

    messageController.clear();

    await chatRepository.sendMessage(
      roomId: roomId!,
      text: text,
    );
  }

  @action
  void dispose() {
    roomId = null;
    _serverMessages = null;
    targetUser = null;
    messageController.dispose();
  }
}
