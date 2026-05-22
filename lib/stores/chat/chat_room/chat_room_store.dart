import 'dart:async';
import 'dart:io';

import 'package:chatkuy/core/helpers/image_saver_helper.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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

  @observable
  File? pickedImage;

  @observable
  File? croppedImage;

  final ObservableList<ChatMessageModel> uploadingMessages =
      ObservableList<ChatMessageModel>();

  final ObservableMap<String, int> uploadProgressByMessageId =
      ObservableMap<String, int>();
  final ObservableMap<String, int> uploadProgressByLocalPath =
      ObservableMap<String, int>();

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

    if (uploadingMessages.isNotEmpty) {
      final visibleUploadingMessages =
          uploadingMessages.where((uploadingMessage) {
        return !list.any(
          (message) =>
              message.type == MessageType.image &&
              message.localImagePath != null &&
              message.localImagePath == uploadingMessage.localImagePath,
        );
      });

      list = [...list, ...visibleUploadingMessages]
        ..sort((a, b) => a.createdAtClient.compareTo(b.createdAtClient));
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

    _serverMessages =
        chatRepository.watchMessages(roomId: roomId).asObservable();

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
    if (roomId == null) return;

    final messageText = text?.trim();
    final imageFile = image ?? pickedImage;

    if ((messageText == null || messageText.isEmpty) && imageFile == null) {
      return;
    }

    /// Clear input
    messageController.clear();
    clearPickedImage();

    ChatMessageModel? uploadingMessage;
    String? localImagePath;

    if (imageFile != null && currentUid != null) {
      final now = DateTime.now();
      localImagePath =
          await saveImageToLocal(imageFile: imageFile, roomId: roomId!);

      uploadingMessage = ChatMessageModel(
        id: 'uploading_${now.microsecondsSinceEpoch}',
        roomId: roomId!,
        senderId: currentUid!,
        text: messageText,
        createdAt: now,
        createdAtClient: now,
        deliveredTo: {},
        readBy: {},
        status: MessageStatus.pending,
        type: MessageType.image,
        localImagePath: localImagePath,
      );

      uploadingMessages.add(uploadingMessage);
      uploadProgressByMessageId[uploadingMessage.id] = 0;
      uploadProgressByLocalPath[localImagePath] = 0;
    }

    try {
      await chatRepository.sendMessage(
        roomId: roomId!,
        text: messageText,
        imageFile: imageFile,
        localImagePath: localImagePath,
        type: imageFile != null ? MessageType.image : MessageType.text,
        onUploadProgress: uploadingMessage == null
            ? null
            : (progress) {
                runInAction(() {
                  uploadProgressByMessageId[uploadingMessage!.id] = progress;

                  if (localImagePath != null) {
                    uploadProgressByLocalPath[localImagePath] = progress;
                  }
                });
              },
      );
    } catch (e) {
      if (uploadingMessage != null) {
        final index = uploadingMessages
            .indexWhere((message) => message.id == uploadingMessage!.id);

        if (index != -1) {
          uploadingMessages[index] =
              uploadingMessage.copyWith(status: MessageStatus.failed);
        }
      }

      rethrow;
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
