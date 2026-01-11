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

  ObservableStream<List<ChatMessageModel>>? _serverMessages;

  @observable
  ObservableList<ChatMessageModel> localMessages = ObservableList<ChatMessageModel>();

  @observable
  String? roomId;

  @observable
  String? currentUid;

  /// 🔥 FINAL messages for UI
  @computed
  List<ChatMessageModel> get messages {
    final server = _serverMessages?.value ?? [];

    final filteredLocal = localMessages.where((local) {
      return !server.any(
        (remote) => remote.clientMessageId != null && remote.clientMessageId == local.clientMessageId,
      );
    });

    final merged = [...server, ...filteredLocal];
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  @action
  void init({
    required String roomId,
    required String currentUid,
  }) {
    this.roomId = roomId;
    this.currentUid = currentUid;

    messageController = TextEditingController();

    _serverMessages = chatRepository.watchMessages(roomId: roomId).asObservable();

    chatRepository.markAsRead(
      roomId: roomId,
      uid: currentUid,
    );
  }

  @action
  Future<void> sendMessage(String text) async {
    if (roomId == null || text.trim().isEmpty) return;

    final clientMessageId = DateTime.now().millisecondsSinceEpoch.toString();

    final localMessage = ChatMessageModel(
      id: clientMessageId,
      senderId: currentUid!,
      text: text,
      createdAt: DateTime.now(),
      clientMessageId: clientMessageId,
      status: MessageStatus.pending,
    );

    localMessages.add(localMessage);
    messageController.clear();

    try {
      await chatRepository.sendMessage(
        roomId: roomId!,
        text: text,
      );
    } catch (_) {
      final index = localMessages.indexWhere((m) => m.id == clientMessageId);
      if (index != -1) {
        localMessages[index] = localMessages[index].copyWith(status: MessageStatus.failed);
      }
    }
  }

  @action
  void dispose() {
    roomId = null;
    _serverMessages = null;
    localMessages.clear();
    messageController.dispose();
  }
}
