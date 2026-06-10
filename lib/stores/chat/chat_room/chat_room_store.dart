import 'dart:async';
import 'dart:io';

import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/core/helpers/image_compress_helper.dart';
import 'package:chatkuy/core/helpers/image_saver_helper.dart';
import 'package:chatkuy/core/helpers/video_compress_helper.dart';
import 'package:chatkuy/data/models/chat_user_item_model.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  ObservableStream<UserModel>? currentUser;
  ObservableStream<Map<String, bool>>? typing;
  final Observable<ChatMessageModel?> replyToMessage =
      Observable<ChatMessageModel?>(null);
  final Observable<String?> unreadDividerMessageId = Observable<String?>(null);
  final Observable<bool> isInitialMessagesLoading = Observable<bool>(true);

  @observable
  String? roomId;

  @observable
  String? currentUid;

  @observable
  File? pickedImage;

  @observable
  File? croppedImage;

  @observable
  String searchQuery = '';

  final ObservableList<ChatMessageModel> uploadingMessages =
      ObservableList<ChatMessageModel>();

  final ObservableMap<String, int> uploadProgressByMessageId =
      ObservableMap<String, int>();
  final ObservableMap<String, int> uploadProgressByLocalPath =
      ObservableMap<String, int>();

  Timer? _resetUnreadTimer;
  Timer? _typingTimer;
  StreamSubscription<List<ChatMessageModel>>? _initialMessageLoadSubscription;
  ReactionDisposer? _messageStatusDisposer;
  bool _isTyping = false;
  bool _didCaptureUnreadDivider = false;
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

      list = box.values
          .where(
            (m) =>
                m.roomId == roomId &&
                (currentUid == null || m.deletedFor[currentUid] != true),
          )
          .toList()
        ..sort((a, b) => a.createdAtClient.compareTo(b.createdAtClient));
    }

    if (uploadingMessages.isNotEmpty) {
      final visibleUploadingMessages =
          uploadingMessages.where((uploadingMessage) {
        return !list.any(
          (message) =>
              message.type == uploadingMessage.type &&
              _localMediaPath(message) != null &&
              _localMediaPath(message) == _localMediaPath(uploadingMessage),
        );
      });

      list = [...list, ...visibleUploadingMessages]
        ..sort((a, b) => a.createdAtClient.compareTo(b.createdAtClient));
    }

    return list;
  }

  @computed
  List<ChatMessageModel> get visibleMessages {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return messages;

    return messages.where((message) {
      final text = message.text?.toLowerCase() ?? '';
      final replyText = message.replyToText?.toLowerCase() ?? '';
      final typeLabel = _messageTypeLabel(message.type).toLowerCase();

      return text.contains(query) ||
          replyText.contains(query) ||
          typeLabel.contains(query);
    }).toList();
  }

  @computed
  int get searchResultCount {
    if (searchQuery.trim().isEmpty) return 0;
    return visibleMessages.length;
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
    _didCaptureUnreadDivider = false;
    unreadDividerMessageId.value = null;
    isInitialMessagesLoading.value = true;

    final messageStream =
        chatRepository.watchMessages(roomId: roomId).asBroadcastStream();
    _serverMessages = messageStream.asObservable();
    _watchInitialMessageLoad(messageStream);

    targetUser = userRepository.watchUser(targetUid).asObservable();
    currentUser = userRepository.watchUser(currentUid).asObservable();
    typing = chatRepository.watchTyping(roomId: roomId).asObservable();

    _messageStatusDisposer?.call();
    _messageStatusDisposer = reaction<List<ChatMessageModel>>(
      (_) => messages,
      _syncMessageStatus,
      fireImmediately: true,
    );

    initReadMessagePeriodically();
  }

  void _watchInitialMessageLoad(Stream<List<ChatMessageModel>> messageStream) {
    _initialMessageLoadSubscription?.cancel();

    var emissionCount = 0;
    _initialMessageLoadSubscription = messageStream.listen(
      (messages) {
        emissionCount += 1;

        if (messages.isNotEmpty || emissionCount >= 2) {
          runInAction(() => isInitialMessagesLoading.value = false);
          _initialMessageLoadSubscription?.cancel();
          _initialMessageLoadSubscription = null;
        }
      },
      onError: (_, __) {
        runInAction(() => isInitialMessagesLoading.value = false);
      },
    );
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

  @action
  void setSearchQuery(String value) {
    searchQuery = value;
  }

  @action
  void clearSearch() {
    searchQuery = '';
  }

  @action
  void setReplyToMessage(ChatMessageModel message) {
    runInAction(() => replyToMessage.value = message);
  }

  @action
  void clearReplyToMessage() {
    runInAction(() => replyToMessage.value = null);
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
    final replyMessage = replyToMessage.value;
    final replySenderName = _replySenderName(replyMessage);
    messageController.clear();
    onTypingChanged('');
    clearPickedImage();
    clearReplyToMessage();

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
        replyToMessageId: replyMessage?.id,
        replyToSenderId: replyMessage?.senderId,
        replyToSenderName: replySenderName,
        replyToText: _replyPreviewText(replyMessage),
        replyToType: replyMessage?.type,
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
        replyToMessage: replyMessage,
        replyToSenderName: replySenderName,
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
          'message_type': imageFile != null
              ? MessageType.image.name
              : MessageType.text.name,
          'has_text': messageText?.isNotEmpty == true,
        },
      );
      if (uploadingMessage != null) {
        final index = uploadingMessages.indexWhere(
          (message) => message.id == uploadingMessage!.id,
        );

        if (index != -1) {
          uploadingMessages[index] =
              uploadingMessage.copyWith(status: MessageStatus.failed);
        }
      }

      rethrow;
    }
  }

  @action
  Future<void> sendVideoMessage(String? text, File video) async {
    if (roomId == null || currentUid == null) return;

    final activeRoomId = roomId!;
    final activeUid = currentUid!;
    final messageText = text?.trim();

    messageController.clear();
    onTypingChanged('');
    final replyMessage = replyToMessage.value;
    final replySenderName = _replySenderName(replyMessage);
    clearReplyToMessage();

    final now = DateTime.now();
    final uploadingMessage = ChatMessageModel(
      id: 'uploading_${now.microsecondsSinceEpoch}',
      roomId: activeRoomId,
      senderId: activeUid,
      text: messageText,
      createdAt: now,
      createdAtClient: now,
      deliveredTo: {},
      readBy: {},
      status: MessageStatus.pending,
      type: MessageType.video,
      localVideoPath: video.path,
      replyToMessageId: replyMessage?.id,
      replyToSenderId: replyMessage?.senderId,
      replyToSenderName: replySenderName,
      replyToText: _replyPreviewText(replyMessage),
      replyToType: replyMessage?.type,
    );

    uploadingMessages.add(uploadingMessage);
    uploadProgressByMessageId[uploadingMessage.id] = 0;
    uploadProgressByLocalPath[video.path] = 0;
    await Hive.box<ChatMessageModel>('chat_messages').put(
      uploadingMessage.id,
      uploadingMessage,
    );
    await _updateLocalChatListItem(uploadingMessage);

    try {
      final uploadVideoFile = await compressChatVideo(
        videoFile: video,
        onProgress: (progress) {
          runInAction(() {
            final mappedProgress =
                (progress * 0.5).round().clamp(0, 50).toInt();
            uploadProgressByMessageId[uploadingMessage.id] = mappedProgress;
            uploadProgressByLocalPath[video.path] = mappedProgress;
          });
        },
      );
      final localVideoPath = await saveVideoToLocal(
        videoFile: uploadVideoFile,
        roomId: activeRoomId,
      );
      final compressedUploadingMessage = uploadingMessage.copyWith(
        localVideoPath: localVideoPath,
      );
      await Hive.box<ChatMessageModel>('chat_messages').put(
        uploadingMessage.id,
        compressedUploadingMessage,
      );
      await _updateLocalChatListItem(compressedUploadingMessage);

      runInAction(() {
        final index = uploadingMessages.indexWhere(
          (message) => message.id == uploadingMessage.id,
        );

        if (index != -1) {
          uploadingMessages[index] = compressedUploadingMessage;
        }

        uploadProgressByMessageId[uploadingMessage.id] =
            uploadProgressByMessageId[uploadingMessage.id]
                    ?.clamp(0, 50)
                    .toInt() ??
                50;
        uploadProgressByLocalPath[localVideoPath] =
            uploadProgressByMessageId[uploadingMessage.id] ?? 50;
      });

      await chatRepository.sendMessage(
        roomId: activeRoomId,
        text: messageText,
        videoFile: uploadVideoFile,
        clientMessageId: uploadingMessage.id,
        localVideoPath: localVideoPath,
        type: MessageType.video,
        replyToMessage: replyMessage,
        replyToSenderName: replySenderName,
        onUploadProgress: (progress) {
          runInAction(() {
            final mappedProgress = (50 + (progress * 0.5)).round();
            uploadProgressByMessageId[uploadingMessage.id] =
                mappedProgress.clamp(50, 100).toInt();
            uploadProgressByLocalPath[localVideoPath] =
                mappedProgress.clamp(50, 100).toInt();
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
        uploadingMessages[index] =
            uploadingMessage.copyWith(status: MessageStatus.failed);
      }
      await Hive.box<ChatMessageModel>('chat_messages').put(
        uploadingMessage.id,
        uploadingMessage.copyWith(status: MessageStatus.failed),
      );
      await _updateLocalChatListItem(
        uploadingMessage.copyWith(status: MessageStatus.failed),
      );

      rethrow;
    }
  }

  Future<void> _updateLocalChatListItem(ChatMessageModel message) async {
    final chatListBox = Hive.box<ChatUserItemModel>('chat_list');
    final existing = chatListBox.get(message.roomId);
    if (existing == null) return;

    await chatListBox.put(
      message.roomId,
      ChatUserItemModel(
        roomId: existing.roomId,
        user: existing.user,
        lastMessage: _resolveLastMessage(message),
        lastMessageAt: message.createdAtClient,
        unreadCount: existing.unreadCount,
        imageUrl: message.imageUrl ?? existing.imageUrl,
        type: message.type,
        lastSenderId: message.senderId,
        lastMessageStatus: message.status,
        lastMessageDeliveredTo: message.deliveredTo,
        lastMessageReadBy: message.readBy,
        isArchived: existing.isArchived,
      ),
    );
  }

  Future<void> sendFileMessage(File file) async {
    if (roomId == null || currentUid == null) return;

    messageController.clear();
    onTypingChanged('');
    final replyMessage = replyToMessage.value;
    final replySenderName = _replySenderName(replyMessage);
    clearReplyToMessage();

    final now = DateTime.now();
    final fileName = p.basename(file.path);
    final fileSize = await file.length();
    final fileExtension =
        p.extension(fileName).replaceFirst('.', '').toUpperCase();
    final localFilePath = await saveFileToLocal(file: file, roomId: roomId!);
    final uploadingMessage = ChatMessageModel(
      id: 'uploading_${now.microsecondsSinceEpoch}',
      roomId: roomId!,
      senderId: currentUid!,
      createdAt: now,
      createdAtClient: now,
      deliveredTo: {},
      readBy: {},
      status: MessageStatus.pending,
      type: MessageType.file,
      localFilePath: localFilePath,
      fileName: fileName,
      fileSize: fileSize,
      fileExtension: fileExtension,
      replyToMessageId: replyMessage?.id,
      replyToSenderId: replyMessage?.senderId,
      replyToSenderName: replySenderName,
      replyToText: _replyPreviewText(replyMessage),
      replyToType: replyMessage?.type,
    );

    uploadingMessages.add(uploadingMessage);
    uploadProgressByMessageId[uploadingMessage.id] = 0;
    uploadProgressByLocalPath[localFilePath] = 0;

    try {
      await chatRepository.sendMessage(
        roomId: roomId!,
        file: File(localFilePath),
        localFilePath: localFilePath,
        fileName: fileName,
        fileSize: fileSize,
        fileExtension: fileExtension,
        type: MessageType.file,
        replyToMessage: replyMessage,
        replyToSenderName: replySenderName,
        onUploadProgress: (progress) {
          runInAction(() {
            uploadProgressByMessageId[uploadingMessage.id] = progress;
            uploadProgressByLocalPath[localFilePath] = progress;
          });
        },
      );
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Send file chat message failed',
        context: {
          'room_id': roomId,
          'current_uid': currentUid,
          'file_name': fileName,
        },
      );
      final index = uploadingMessages.indexWhere(
        (message) => message.id == uploadingMessage.id,
      );

      if (index != -1) {
        uploadingMessages[index] =
            uploadingMessage.copyWith(status: MessageStatus.failed);
      }

      rethrow;
    }
  }

  Future<void> sendAudioMessage({
    required File audioFile,
    required Duration duration,
  }) async {
    if (roomId == null || currentUid == null) return;

    messageController.clear();
    onTypingChanged('');
    final replyMessage = replyToMessage.value;
    final replySenderName = _replySenderName(replyMessage);
    clearReplyToMessage();

    final now = DateTime.now();
    final localAudioPath = await saveAudioToLocal(
      audioFile: audioFile,
      roomId: roomId!,
    );
    final durationSeconds = duration.inSeconds <= 0 ? 1 : duration.inSeconds;
    final uploadingMessage = ChatMessageModel(
      id: 'uploading_${now.microsecondsSinceEpoch}',
      roomId: roomId!,
      senderId: currentUid!,
      createdAt: now,
      createdAtClient: now,
      deliveredTo: {},
      readBy: {},
      status: MessageStatus.pending,
      type: MessageType.audio,
      localAudioPath: localAudioPath,
      audioDurationSeconds: durationSeconds,
      replyToMessageId: replyMessage?.id,
      replyToSenderId: replyMessage?.senderId,
      replyToSenderName: replySenderName,
      replyToText: _replyPreviewText(replyMessage),
      replyToType: replyMessage?.type,
    );

    uploadingMessages.add(uploadingMessage);
    uploadProgressByMessageId[uploadingMessage.id] = 0;
    uploadProgressByLocalPath[localAudioPath] = 0;

    try {
      await chatRepository.sendMessage(
        roomId: roomId!,
        audioFile: File(localAudioPath),
        localAudioPath: localAudioPath,
        audioDurationSeconds: durationSeconds,
        type: MessageType.audio,
        replyToMessage: replyMessage,
        replyToSenderName: replySenderName,
        onUploadProgress: (progress) {
          runInAction(() {
            uploadProgressByMessageId[uploadingMessage.id] = progress;
            uploadProgressByLocalPath[localAudioPath] = progress;
          });
        },
      );
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Send audio chat message failed',
        context: {
          'room_id': roomId,
          'current_uid': currentUid,
          'duration_seconds': durationSeconds,
        },
      );
      final index = uploadingMessages.indexWhere(
        (message) => message.id == uploadingMessage.id,
      );

      if (index != -1) {
        uploadingMessages[index] =
            uploadingMessage.copyWith(status: MessageStatus.failed);
      }

      rethrow;
    }
  }

  Future<File> createAudioRecordingFile() async {
    final directory = await getTemporaryDirectory();
    final fileName = 'voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    return File(p.join(directory.path, fileName));
  }

  Future<void> sendContactMessage({
    required String name,
    required String phone,
  }) async {
    if (roomId == null || currentUid == null) return;

    final contactName = name.trim().isEmpty ? 'Kontak' : name.trim();
    final contactPhone = phone.trim();
    if (contactPhone.isEmpty) return;

    messageController.clear();
    onTypingChanged('');
    final replyMessage = replyToMessage.value;
    final replySenderName = _replySenderName(replyMessage);
    clearReplyToMessage();

    try {
      await chatRepository.sendMessage(
        roomId: roomId!,
        type: MessageType.contact,
        contactName: contactName,
        contactPhone: contactPhone,
        replyToMessage: replyMessage,
        replyToSenderName: replySenderName,
      );
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Send contact chat message failed',
        context: {
          'room_id': roomId,
          'current_uid': currentUid,
          'contact_name': contactName,
        },
      );
      rethrow;
    }
  }

  String? _localMediaPath(ChatMessageModel message) {
    if (message.type == MessageType.file) return message.localFilePath;
    if (message.type == MessageType.video) return message.localVideoPath;
    if (message.type == MessageType.audio) return message.localAudioPath;
    return message.localImagePath;
  }

  String? _replySenderName(ChatMessageModel? message) {
    if (message == null) return null;
    if (message.senderId == currentUid) return 'Anda';
    return targetUser?.value?.name ?? 'Kontak';
  }

  String? _replyPreviewText(ChatMessageModel? message) {
    if (message == null) return null;

    final messageText = message.text?.trim();
    if (messageText != null && messageText.isNotEmpty) return messageText;
    if (message.type == MessageType.image) return 'Foto';
    if (message.type == MessageType.video) return 'Video';
    if (message.type == MessageType.call) return 'Panggilan';
    if (message.type == MessageType.file) return 'Dokumen';
    if (message.type == MessageType.contact) return 'Kontak';
    if (message.type == MessageType.audio) return 'Pesan suara';
    return null;
  }

  String _messageTypeLabel(MessageType type) {
    if (type == MessageType.image) return 'Foto';
    if (type == MessageType.video) return 'Video';
    if (type == MessageType.call) return 'Panggilan';
    if (type == MessageType.file) return 'Dokumen';
    if (type == MessageType.contact) return 'Kontak';
    if (type == MessageType.audio) return 'Pesan suara';
    return 'Pesan';
  }

  String? _resolveLastMessage(ChatMessageModel message) {
    final text = message.text?.trim();
    if (text != null && text.isNotEmpty) return text;
    if (message.type == MessageType.image) return 'Foto';
    if (message.type == MessageType.video) return 'Video';
    if (message.type == MessageType.call) return 'Panggilan';
    if (message.type == MessageType.file) return 'Dokumen';
    if (message.type == MessageType.contact) return 'Kontak';
    if (message.type == MessageType.audio) return 'Pesan suara';
    return null;
  }

  @action
  Future<void> deleteMessageForMe(ChatMessageModel message) async {
    if (roomId == null || currentUid == null) return;

    clearReplyToMessage();
    uploadProgressByMessageId.remove(message.id);

    final localMediaPath = _localMediaPath(message);
    if (localMediaPath != null) {
      uploadProgressByLocalPath.remove(localMediaPath);
    }

    final isUploadingMessage =
        uploadingMessages.any((item) => item.id == message.id);
    uploadingMessages.removeWhere((item) => item.id == message.id);
    if (isUploadingMessage) return;

    try {
      await chatRepository.deleteMessageForMe(
        roomId: roomId!,
        messageId: message.id,
        uid: currentUid!,
      );
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Delete chat message for current user failed',
        context: {
          'room_id': roomId,
          'message_id': message.id,
          'current_uid': currentUid,
        },
      );
      rethrow;
    }
  }

  @action
  Future<void> deleteMessagesForMe(Iterable<ChatMessageModel> messages) async {
    if (roomId == null || currentUid == null) return;

    final uniqueMessages = <String, ChatMessageModel>{
      for (final message in messages) message.id: message,
    }.values.toList();

    if (uniqueMessages.isEmpty) return;

    clearReplyToMessage();

    final uploadingMessageIds =
        uploadingMessages.map((item) => item.id).toSet();

    for (final message in uniqueMessages) {
      uploadProgressByMessageId.remove(message.id);

      final localMediaPath = _localMediaPath(message);
      if (localMediaPath != null) {
        uploadProgressByLocalPath.remove(localMediaPath);
      }
    }

    uploadingMessages.removeWhere(
      (item) => uniqueMessages.any((message) => message.id == item.id),
    );

    final persistedMessages = uniqueMessages
        .where((message) => !uploadingMessageIds.contains(message.id))
        .toList();

    if (persistedMessages.isEmpty) return;

    try {
      await Future.wait(
        persistedMessages.map(
          (message) => chatRepository.deleteMessageForMe(
            roomId: roomId!,
            messageId: message.id,
            uid: currentUid!,
          ),
        ),
      );
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Delete selected chat messages for current user failed',
        context: {
          'room_id': roomId,
          'message_count': persistedMessages.length,
          'current_uid': currentUid,
        },
      );
      rethrow;
    }
  }

  void initReadMessagePeriodically() {
    _resetUnreadTimer?.cancel();
    _resetUnread();
  }

  // -----------------------
  // SYNC DELIVERED / READ
  // -----------------------
  void _syncMessageStatus(List<ChatMessageModel> messages) {
    if (roomId == null || currentUid == null) return;

    _captureUnreadDivider(messages);

    for (final message in messages) {
      if (message.senderId == currentUid) continue;

      if (!message.deliveredTo.containsKey(currentUid) &&
          _deliveredMessageIds.add(message.id)) {
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

      if (!message.readBy.containsKey(currentUid) &&
          _readMessageIds.add(message.id)) {
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

    _scheduleResetUnread();
  }

  void _captureUnreadDivider(List<ChatMessageModel> messages) {
    if (_didCaptureUnreadDivider || currentUid == null || messages.isEmpty) {
      return;
    }

    _didCaptureUnreadDivider = true;

    final firstUnreadIndex = messages.indexWhere(
      (message) =>
          message.senderId != currentUid &&
          !message.readBy.containsKey(currentUid),
    );
    if (firstUnreadIndex == -1) return;

    unreadDividerMessageId.value = messages[firstUnreadIndex].id;
  }

  void _scheduleResetUnread() {
    _resetUnreadTimer?.cancel();
    _resetUnreadTimer = Timer(const Duration(milliseconds: 600), _resetUnread);
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
    _initialMessageLoadSubscription?.cancel();
    _initialMessageLoadSubscription = null;
    _messageStatusDisposer?.call();
    _messageStatusDisposer = null;
    _deliveredMessageIds.clear();
    _readMessageIds.clear();
    _didCaptureUnreadDivider = false;
    roomId = null;
    _serverMessages = null;
    targetUser = null;
    currentUser = null;
    typing = null;
    replyToMessage.value = null;
    unreadDividerMessageId.value = null;
    isInitialMessagesLoading.value = true;
    searchQuery = '';
    messageController.dispose();
  }
}
