import 'dart:async';
import 'dart:io';

import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';

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

  /// 🔥 IMAGE SUPPORT
  @observable
  File? pickedImage;

  @observable
  File? croppedImage;

  @computed
  List<ChatMessageModel> get messages {
    List<ChatMessageModel> list;

    /// PRIORITAS SERVER DATA
    if (_serverMessages?.value != null && _serverMessages!.value!.isNotEmpty) {
      list = _serverMessages!.value!;
    } else {
      /// FALLBACK HIVE (OFFLINE MODE)
      if (roomId == null) return [];

      final box = Hive.box<ChatMessageModel>('chat_messages');

      list = box.values.where((m) => m.id.contains(roomId!)).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

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

    initReadMessagePeriodically();
  }

  // -----------------------
  // IMAGE CONTROL
  // -----------------------
  @action
  void setPickedImage(File file) {
    pickedImage = file;
  }

  @action
  void clearPickedImage() {
    pickedImage = null;
  }

  // -----------------------
  // SEND MESSAGE
  // -----------------------
  @action
  Future<void> sendMessage(String? text, File? image) async {
    if (roomId == null || currentUid == null) return;

    final messageText = text?.trim();
    final imageFile = image ?? pickedImage;

    if ((messageText == null || messageText.isEmpty) && imageFile == null) {
      return;
    }

    /// TEMP ID
    final tempId = DateTime.now().microsecondsSinceEpoch.toString();

    final now = DateTime.now();

    /// INSERT LOCAL PENDING (TANPA IMAGE URL DULU)
    final box = Hive.box<ChatMessageModel>('chat_messages');

    final localMessage = ChatMessageModel(
      id: tempId,
      senderId: currentUid!,
      text: messageText,
      imageUrl: null, // belum ada
      type: imageFile != null ? MessageType.image : MessageType.text,
      createdAt: now,
      createdAtClient: now,
      deliveredTo: {},
      readBy: {},
      status: MessageStatus.pending,
    );

    box.put(tempId, localMessage);

    /// CLEAR INPUT LANGSUNG
    messageController.clear();
    clearPickedImage();

    try {
      String? imageUrl;

      /// UPLOAD IMAGE (BACKGROUND)
      if (imageFile != null) {
        imageUrl = await chatRepository.uploadImage(
          file: imageFile,
          roomId: roomId!,
        );
      }

      /// KIRIM KE FIRESTORE
      await chatRepository.sendMessage(
        roomId: roomId!,
        text: messageText,
        imageUrl: imageUrl,
        type: imageFile != null ? MessageType.image : MessageType.text,
      );

      /// Tidak perlu update Hive.
      /// Snapshot Firestore akan override message.
    } catch (e) {
      /// UPDATE STATUS JIKA GAGAL
      final failed = localMessage.copyWith(status: MessageStatus.failed);

      box.put(tempId, failed);
    }
  }

  void initReadMessagePeriodically() {
    Timer.periodic(const Duration(milliseconds: 500), (_) {
      _resetUnread();
    });
  }

  // -----------------------
  // SYNC DELIVERED / READ
  // -----------------------
  void _syncMessageStatus(List<ChatMessageModel> messages) {
    if (roomId == null || currentUid == null) return;

    for (final message in messages) {
      if (message.senderId == currentUid) continue;

      if (!message.deliveredTo.containsKey(currentUid)) {
        chatRepository.markDelivered(
          roomId: roomId!,
          messageId: message.id,
          uid: currentUid!,
        );
      }

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

  Future<void> _resetUnread() async {
    if (roomId == null || currentUid == null) return;

    await chatRepository.resetUnread(
      roomId: roomId!,
      uid: currentUid!,
    );
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
