import 'dart:async';
import 'dart:io';

import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/core/helpers/image_compress_helper.dart';
import 'package:chatkuy/core/helpers/image_saver_helper.dart';
import 'package:chatkuy/core/helpers/video_compress_helper.dart';
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

  final TextEditingController messageController = TextEditingController();

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

  final ObservableList<ChatMessageModel> uploadingMessages = ObservableList<ChatMessageModel>();

  final ObservableMap<String, int> uploadProgressByMessageId = ObservableMap<String, int>();
  final ObservableMap<String, int> uploadProgressByLocalPath = ObservableMap<String, int>();

  Timer? _resetUnreadTimer;
  Timer? _typingTimer;
  ReactionDisposer? _messageStatusDisposer;
  bool _isTyping = false;
  final Set<String> _deliveredMessageIds = {};
  final Set<String> _readMessageIds = {};

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

      list = box.values.where((m) => m.roomId == roomId).toList()
        ..sort((a, b) => a.createdAtClient.compareTo(b.createdAtClient));
    }

    if (uploadingMessages.isNotEmpty) {
      final visibleUploadingMessages = uploadingMessages.where((uploadingMessage) {
        return !list.any(
          (message) =>
              message.type == uploadingMessage.type &&
              _localMediaPath(message) != null &&
              _localMediaPath(message) == _localMediaPath(uploadingMessage),
        );
      });

      list = [...list, ...visibleUploadingMessages]..sort((a, b) => a.createdAtClient.compareTo(b.createdAtClient));
    }

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

    _serverMessages = chatRepository.watchMessages(roomId: roomId).asObservable();

    targetUser = userRepository.watchUser(targetUid).asObservable();
    typing = chatRepository.watchTyping(roomId: roomId).asObservable();

    _messageStatusDisposer?.call();
    _messageStatusDisposer = reaction<List<ChatMessageModel>>(
      (_) => messages,
      _syncMessageStatus,
      fireImmediately: true,
    );

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
    onTypingChanged('');
    clearPickedImage();

    ChatMessageModel? uploadingMessage;
    String? localImagePath;
    File? uploadImageFile;

    if (imageFile != null && currentUid != null) {
      final now = DateTime.now();
      uploadImageFile = await compressChatImage(imageFile: imageFile);
      localImagePath = await saveImageToLocal(
        imageFile: uploadImageFile,
        roomId: roomId!,
      );

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
        imageFile: uploadImageFile ?? imageFile,
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
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Send chat message failed',
        context: {
          'room_id': roomId,
          'current_uid': currentUid,
          'message_type': imageFile != null ? MessageType.image.name : MessageType.text.name,
          'has_text': messageText?.isNotEmpty == true,
        },
      );
      if (uploadingMessage != null) {
        final index = uploadingMessages.indexWhere(
          (message) => message.id == uploadingMessage!.id,
        );

        if (index != -1) {
          uploadingMessages[index] = uploadingMessage.copyWith(status: MessageStatus.failed);
        }
      }

      rethrow;
    }
  }

  @action
  Future<void> sendVideoMessage(String? text, File video) async {
    if (roomId == null || currentUid == null) return;

    final messageText = text?.trim();

    messageController.clear();
    onTypingChanged('');

    final now = DateTime.now();
    final uploadingMessage = ChatMessageModel(
      id: 'uploading_${now.microsecondsSinceEpoch}',
      roomId: roomId!,
      senderId: currentUid!,
      text: messageText,
      createdAt: now,
      createdAtClient: now,
      deliveredTo: {},
      readBy: {},
      status: MessageStatus.pending,
      type: MessageType.video,
      localVideoPath: video.path,
    );

    uploadingMessages.add(uploadingMessage);
    uploadProgressByMessageId[uploadingMessage.id] = 0;
    uploadProgressByLocalPath[video.path] = 0;

    try {
      final uploadVideoFile = await compressChatVideo(
        videoFile: video,
        onProgress: (progress) {
          runInAction(() {
            final mappedProgress = (progress * 0.5).round().clamp(0, 50).toInt();
            uploadProgressByMessageId[uploadingMessage.id] = mappedProgress;
            uploadProgressByLocalPath[video.path] = mappedProgress;
          });
        },
      );
      final localVideoPath = await saveVideoToLocal(
        videoFile: uploadVideoFile,
        roomId: roomId!,
      );

      runInAction(() {
        final index = uploadingMessages.indexWhere(
          (message) => message.id == uploadingMessage.id,
        );

        if (index != -1) {
          uploadingMessages[index] = uploadingMessage.copyWith(localVideoPath: localVideoPath);
        }

        uploadProgressByMessageId[uploadingMessage.id] =
            uploadProgressByMessageId[uploadingMessage.id]?.clamp(0, 50).toInt() ?? 50;
        uploadProgressByLocalPath[localVideoPath] = uploadProgressByMessageId[uploadingMessage.id] ?? 50;
      });

      await chatRepository.sendMessage(
        roomId: roomId!,
        text: messageText,
        videoFile: uploadVideoFile,
        localVideoPath: localVideoPath,
        type: MessageType.video,
        onUploadProgress: (progress) {
          runInAction(() {
            final mappedProgress = (50 + (progress * 0.5)).round();
            uploadProgressByMessageId[uploadingMessage.id] = mappedProgress.clamp(50, 100).toInt();
            uploadProgressByLocalPath[localVideoPath] = mappedProgress.clamp(50, 100).toInt();
          });
        },
      );
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Send video chat message failed',
        context: {
          'room_id': roomId,
          'current_uid': currentUid,
          'has_text': messageText?.isNotEmpty == true,
        },
      );
      final index = uploadingMessages.indexWhere(
        (message) => message.id == uploadingMessage.id,
      );

      if (index != -1) {
        uploadingMessages[index] = uploadingMessage.copyWith(status: MessageStatus.failed);
      }

      rethrow;
    }
  }

  String? _localMediaPath(ChatMessageModel message) {
    if (message.type == MessageType.video) return message.localVideoPath;
    return message.localImagePath;
  }

  void initReadMessagePeriodically() {
    _resetUnreadTimer?.cancel();
    _resetUnreadTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _resetUnread();
    });
    _resetUnread();
  }

  // -----------------------
  // SYNC DELIVERED / READ
  // -----------------------
  void _syncMessageStatus(List<ChatMessageModel> messages) {
    if (roomId == null || currentUid == null) return;

    for (final message in messages) {
      if (message.senderId == currentUid) continue;

      if (!message.deliveredTo.containsKey(currentUid) && _deliveredMessageIds.add(message.id)) {
        chatRepository
            .markDelivered(
          roomId: roomId!,
          messageId: message.id,
          uid: currentUid!,
        )
            .catchError((error, stackTrace) {
          AppErrorLogger.recordError(
            error,
            stackTrace,
            reason: 'Mark message delivered failed',
            context: {
              'room_id': roomId,
              'message_id': message.id,
              'current_uid': currentUid,
            },
          );
        });
      }

      if (!message.readBy.containsKey(currentUid) && _readMessageIds.add(message.id)) {
        chatRepository
            .markRead(
          roomId: roomId!,
          messageId: message.id,
          uid: currentUid!,
        )
            .catchError((error, stackTrace) {
          AppErrorLogger.recordError(
            error,
            stackTrace,
            reason: 'Mark message read failed',
            context: {
              'room_id': roomId,
              'message_id': message.id,
              'current_uid': currentUid,
            },
          );
        });
      }
    }
  }

  // -----------------------
  // TYPING
  // -----------------------
  @action
  void onTypingChanged(String text) {
    if (roomId == null || currentUid == null) return;

    final nextIsTyping = text.trim().isNotEmpty;

    if (_isTyping != nextIsTyping) {
      _isTyping = nextIsTyping;
      chatRepository
          .setTyping(
        roomId: roomId!,
        uid: currentUid!,
        isTyping: nextIsTyping,
      )
          .catchError((error, stackTrace) {
        AppErrorLogger.recordError(
          error,
          stackTrace,
          reason: 'Set typing state failed',
          context: {
            'room_id': roomId,
            'current_uid': currentUid,
            'is_typing': nextIsTyping,
          },
        );
      });
    }

    _typingTimer?.cancel();
    if (!nextIsTyping) return;

    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      chatRepository
          .setTyping(
        roomId: roomId!,
        uid: currentUid!,
        isTyping: false,
      )
          .catchError((error, stackTrace) {
        AppErrorLogger.recordError(
          error,
          stackTrace,
          reason: 'Clear typing state after timeout failed',
          context: {
            'room_id': roomId,
            'current_uid': currentUid,
          },
        );
      });
    });
  }

  Future<void> _resetUnread() async {
    if (roomId == null || currentUid == null) return;

    try {
      await chatRepository.resetUnread(
        roomId: roomId!,
        uid: currentUid!,
      );
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Reset unread count failed',
        context: {
          'room_id': roomId,
          'current_uid': currentUid,
        },
      );
    }
  }

  // -----------------------
  // DISPOSE
  // -----------------------
  @action
  void dispose() {
    if (roomId != null && currentUid != null) {
      chatRepository
          .setTyping(
        roomId: roomId!,
        uid: currentUid!,
        isTyping: false,
      )
          .catchError((error, stackTrace) {
        AppErrorLogger.recordError(
          error,
          stackTrace,
          reason: 'Clear typing state on dispose failed',
          context: {
            'room_id': roomId,
            'current_uid': currentUid,
          },
        );
      });
    }

    _typingTimer?.cancel();
    _resetUnreadTimer?.cancel();
    _messageStatusDisposer?.call();
    _messageStatusDisposer = null;
    _deliveredMessageIds.clear();
    _readMessageIds.clear();
    roomId = null;
    _serverMessages = null;
    targetUser = null;
    typing = null;
    messageController.dispose();
  }
}
