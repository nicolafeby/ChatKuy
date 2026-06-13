import 'dart:async';
import 'dart:io';

import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/core/helpers/image_compress_helper.dart';
import 'package:chatkuy/core/helpers/image_saver_helper.dart';
import 'package:chatkuy/core/helpers/video_compress_helper.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
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

  static final Set<String> _initialRemoteLoadedRoomIds = {};

  final ChatRepository chatRepository;
  final UserRepository userRepository;

  final TextEditingController messageController = TextEditingController();

  ObservableStream<List<ChatMessageModel>>? _serverMessages;
  ObservableStream<UserModel>? targetUser;
  ObservableStream<UserModel>? currentUser;
  ObservableStream<ChatRoomModel>? room;
  ObservableStream<List<UserModel>>? groupMembers;
  ObservableStream<Map<String, bool>>? typing;
  final Observable<ChatMessageModel?> replyToMessage =
      Observable<ChatMessageModel?>(null);
  final Observable<ChatMessageModel?> editingMessage =
      Observable<ChatMessageModel?>(null);
  final Observable<String?> unreadDividerMessageId = Observable<String?>(null);
  final Observable<bool> isInitialMessagesLoading = Observable<bool>(true);

  @observable
  String? roomId;

  @observable
  String? currentUid;

  String? targetUid;

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
  Timer? _initialMessageLoadFallbackTimer;
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
    String? targetUid,
    bool isGroup = false,
  }) {
    this.roomId = roomId;
    this.currentUid = currentUid;
    this.targetUid = targetUid;
    _didCaptureUnreadDivider = false;
    unreadDividerMessageId.value = null;
    final shouldFetchInitialRemote =
        !_initialRemoteLoadedRoomIds.contains(roomId);
    isInitialMessagesLoading.value = shouldFetchInitialRemote;

    final messageStream =
        chatRepository.watchMessages(roomId: roomId).asBroadcastStream();
    if (shouldFetchInitialRemote) {
      _watchInitialMessageLoad(messageStream);
    } else {
      _initialMessageLoadSubscription?.cancel();
      _initialMessageLoadFallbackTimer?.cancel();
      _initialMessageLoadSubscription = null;
      _initialMessageLoadFallbackTimer = null;
    }
    _serverMessages = messageStream.asObservable();

    room = chatRepository.watchRoom(roomId: roomId).asObservable();
    groupMembers = isGroup
        ? chatRepository.watchGroupMembers(roomId: roomId).asObservable()
        : null;
    targetUser = targetUid == null
        ? null
        : userRepository.watchUser(targetUid).asObservable();
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
    _initialMessageLoadFallbackTimer?.cancel();

    var emissionCount = 0;
    var didCompleteInitialLoad = false;
    final activeRoomId = roomId;

    void completeInitialLoad({
      required bool enforceMinimumDuration,
      required bool markRemoteLoaded,
    }) {
      if (didCompleteInitialLoad) return;
      didCompleteInitialLoad = true;

      final delay = enforceMinimumDuration
          ? const Duration(milliseconds: 700)
          : Duration.zero;

      Future<void>.delayed(
        delay,
        () {
          if (roomId != activeRoomId) return;
          if (markRemoteLoaded && activeRoomId != null) {
            _initialRemoteLoadedRoomIds.add(activeRoomId);
          }
          runInAction(() => isInitialMessagesLoading.value = false);
        },
      );

      _initialMessageLoadFallbackTimer?.cancel();
      _initialMessageLoadFallbackTimer = null;
      _initialMessageLoadSubscription?.cancel();
      _initialMessageLoadSubscription = null;
    }

    _initialMessageLoadFallbackTimer = Timer(const Duration(seconds: 3), () {
      completeInitialLoad(
        enforceMinimumDuration: false,
        markRemoteLoaded: false,
      );
    });

    _initialMessageLoadSubscription = messageStream.listen(
      (messages) {
        emissionCount += 1;

        if (emissionCount >= 2) {
          completeInitialLoad(
            enforceMinimumDuration: true,
            markRemoteLoaded: true,
          );
        }
      },
      onError: (_, __) {
        completeInitialLoad(
          enforceMinimumDuration: false,
          markRemoteLoaded: false,
        );
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

  bool get isCurrentUserGroupAdmin {
    final uid = currentUid;
    final activeRoom = room?.value;
    if (uid == null || activeRoom == null || !activeRoom.isGroup) return false;
    return activeRoom.admins.contains(uid);
  }

  bool get isMuted {
    final uid = currentUid;
    final activeRoom = room?.value;
    if (uid == null || activeRoom == null) return false;
    return activeRoom.isMutedFor(uid);
  }

  List<UserModel> get mentionSuggestions {
    final text = messageController.text;
    final cursor = messageController.selection.baseOffset;
    final query = _activeMentionQuery(text, cursor);
    if (query == null) return const [];

    final lowerQuery = query.toLowerCase();
    return (groupMembers?.value ?? const <UserModel>[])
        .where((user) => user.id != currentUid)
        .where((user) {
          final name = user.name.toLowerCase();
          final username = user.username?.toLowerCase() ?? '';
          return name.contains(lowerQuery) || username.contains(lowerQuery);
        })
        .take(6)
        .toList();
  }

  void insertMention(UserModel user) {
    final text = messageController.text;
    final selection = messageController.selection;
    final cursor =
        selection.baseOffset < 0 ? text.length : selection.baseOffset;
    final start = text.lastIndexOf('@', cursor - 1);
    if (start == -1) return;

    final replacement = '@${user.name} ';
    final newText = text.replaceRange(start, cursor, replacement);
    messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  Future<void> inviteGroupMembers(List<String> memberUids) async {
    if (roomId == null || currentUid == null) return;
    await chatRepository.inviteGroupMembers(
      roomId: roomId!,
      adminUid: currentUid!,
      memberUids: memberUids,
    );
  }

  Future<void> promoteGroupAdmin(String memberUid) async {
    if (roomId == null || currentUid == null) return;
    await chatRepository.promoteGroupAdmin(
      roomId: roomId!,
      adminUid: currentUid!,
      memberUid: memberUid,
    );
  }

  Future<void> removeGroupMember(String memberUid) async {
    if (roomId == null || currentUid == null) return;
    await chatRepository.removeGroupMember(
      roomId: roomId!,
      adminUid: currentUid!,
      memberUid: memberUid,
    );
  }

  Future<void> updateGroupInfo({
    String? name,
    String? photoUrl,
  }) async {
    if (roomId == null || currentUid == null) return;
    await chatRepository.updateGroupInfo(
      roomId: roomId!,
      adminUid: currentUid!,
      name: name,
      photoUrl: photoUrl,
    );
  }

  Future<void> muteChatUntil(DateTime mutedUntil) async {
    if (roomId == null || currentUid == null) return;
    await chatRepository.muteChatUntil(
      roomId: roomId!,
      uid: currentUid!,
      mutedUntil: mutedUntil,
    );
  }

  Future<void> unmuteChat() async {
    if (roomId == null || currentUid == null) return;
    await chatRepository.unmuteChat(
      roomId: roomId!,
      uid: currentUid!,
    );
  }

  @action
  void setReplyToMessage(ChatMessageModel message) {
    runInAction(() {
      replyToMessage.value = message;
      editingMessage.value = null;
    });
  }

  @action
  void clearReplyToMessage() {
    runInAction(() => replyToMessage.value = null);
  }

  @action
  void setEditingMessage(ChatMessageModel message) {
    runInAction(() {
      editingMessage.value = message;
      replyToMessage.value = null;
      messageController.text = message.text?.trim() ?? '';
      messageController.selection = TextSelection.collapsed(
        offset: messageController.text.length,
      );
    });
  }

  @action
  void clearEditingMessage() {
    runInAction(() {
      editingMessage.value = null;
      messageController.clear();
    });
  }

  // -----------------------
  // SEND MESSAGE
  // -----------------------
  @action
  Future<void> sendMessage(String? text, File? image) async {
    if (roomId == null) return;

    final messageText = text?.trim();
    final imageFile = image ?? pickedImage;
    final editTarget = editingMessage.value;

    if (editTarget != null && imageFile == null) {
      await editMessage(editTarget, messageText ?? '');
      return;
    }

    if ((messageText == null || messageText.isEmpty) && imageFile == null) {
      return;
    }

    /// Clear input
    final replyMessage = replyToMessage.value;
    final replySenderName = _replySenderName(replyMessage);
    final mentionedMembers = _mentionedMembersFromText(messageText);
    messageController.clear();
    onTypingChanged('');
    clearPickedImage();
    clearReplyToMessage();
    editingMessage.value = null;

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
        senderName: currentUser?.value?.name,
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
        mentionedUserIds: mentionedMembers.map((user) => user.id).toList(),
        mentionedUserNames: mentionedMembers.map((user) => user.name).toList(),
      );

      uploadingMessages.add(uploadingMessage);
      uploadProgressByMessageId[uploadingMessage.id] = 0;
      uploadProgressByLocalPath[localImagePath] = 0;
    }

    try {
      await chatRepository.sendMessage(
        roomId: roomId!,
        targetUid: targetUid,
        text: messageText,
        imageFile: uploadImageFile ?? imageFile,
        localImagePath: localImagePath,
        type: imageFile != null ? MessageType.image : MessageType.text,
        replyToMessage: replyMessage,
        replyToSenderName: replySenderName,
        mentionedUserIds: mentionedMembers.map((user) => user.id).toList(),
        mentionedUserNames: mentionedMembers.map((user) => user.name).toList(),
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
    final mentionedMembers = _mentionedMembersFromText(messageText);
    clearReplyToMessage();

    final now = DateTime.now();
    final uploadingMessage = ChatMessageModel(
      id: 'uploading_${now.microsecondsSinceEpoch}',
      roomId: activeRoomId,
      senderId: activeUid,
      senderName: currentUser?.value?.name,
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
      mentionedUserIds: mentionedMembers.map((user) => user.id).toList(),
      mentionedUserNames: mentionedMembers.map((user) => user.name).toList(),
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
        targetUid: targetUid,
        text: messageText,
        videoFile: uploadVideoFile,
        clientMessageId: uploadingMessage.id,
        localVideoPath: localVideoPath,
        type: MessageType.video,
        replyToMessage: replyMessage,
        replyToSenderName: replySenderName,
        mentionedUserIds: mentionedMembers.map((user) => user.id).toList(),
        mentionedUserNames: mentionedMembers.map((user) => user.name).toList(),
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
        isGroup: existing.isGroup,
        groupName: existing.groupName,
        groupPhotoUrl: existing.groupPhotoUrl,
        participants: existing.participants,
        admins: existing.admins,
        mutedUntil: existing.mutedUntil,
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
      senderName: currentUser?.value?.name,
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
        targetUid: targetUid,
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
      senderName: currentUser?.value?.name,
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
        targetUid: targetUid,
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
        targetUid: targetUid,
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
    final member = groupMembers?.value?.firstWhere(
      (user) => user.id == message.senderId,
      orElse: () => UserModel(
        id: '',
        name: '',
        email: '',
        isEmailVerified: false,
        fcmToken: '',
      ),
    );
    if (member != null && member.id.isNotEmpty) return member.name;
    return targetUser?.value?.name ?? 'Kontak';
  }

  List<UserModel> _mentionedMembersFromText(String? text) {
    final messageText = text?.trim();
    final members = groupMembers?.value ?? const <UserModel>[];
    if (messageText == null || messageText.isEmpty || members.isEmpty) {
      return const [];
    }

    final lowerText = messageText.toLowerCase();
    final mentioned = <String, UserModel>{};
    for (final member in members) {
      if (member.id == currentUid) continue;
      final name = member.name.trim();
      if (name.isEmpty) continue;

      final username = member.username?.trim();
      final patterns = <String>[
        '@${name.toLowerCase()}',
        if (username != null && username.isNotEmpty)
          '@${username.toLowerCase()}',
      ];

      if (patterns.any(lowerText.contains)) {
        mentioned[member.id] = member;
      }
    }

    return mentioned.values.toList();
  }

  String? _activeMentionQuery(String text, int cursor) {
    if (cursor <= 0 || cursor > text.length) return null;

    final start = text.lastIndexOf('@', cursor - 1);
    if (start == -1) return null;
    if (start > 0 && !RegExp(r'\s').hasMatch(text[start - 1])) return null;

    final query = text.substring(start + 1, cursor);
    if (query.contains(RegExp(r'\s'))) return null;
    return query;
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
    if (editingMessage.value?.id == message.id) {
      clearEditingMessage();
    }
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
    if (uniqueMessages
        .any((message) => message.id == editingMessage.value?.id)) {
      clearEditingMessage();
    }

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

  @action
  Future<void> editMessage(ChatMessageModel message, String text) async {
    if (roomId == null || currentUid == null) return;
    if (message.senderId != currentUid) return;
    if (message.type != MessageType.text) return;
    if (message.deletedForEveryone) return;

    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final previousText = message.text?.trim() ?? '';
    if (cleanText == previousText) {
      clearEditingMessage();
      onTypingChanged('');
      return;
    }

    try {
      await chatRepository.editMessage(
        roomId: roomId!,
        messageId: message.id,
        text: cleanText,
        uid: currentUid!,
      );
      clearEditingMessage();
      onTypingChanged('');
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Edit chat message failed',
        context: {
          'room_id': roomId,
          'message_id': message.id,
          'current_uid': currentUid,
        },
      );
    }
  }

  @action
  Future<void> deleteMessagesForEveryone(
    Iterable<ChatMessageModel> messages,
  ) async {
    if (roomId == null || currentUid == null) return;

    final uniqueMessages = <String, ChatMessageModel>{
      for (final message in messages) message.id: message,
    }.values.where((message) {
      return message.senderId == currentUid &&
          message.status == MessageStatus.sent &&
          !message.deletedForEveryone;
    }).toList();

    if (uniqueMessages.isEmpty) return;

    clearReplyToMessage();
    if (uniqueMessages
        .any((message) => message.id == editingMessage.value?.id)) {
      clearEditingMessage();
    }

    try {
      await Future.wait(
        uniqueMessages.map(
          (message) => chatRepository.deleteMessageForEveryone(
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
        reason: 'Delete selected chat messages for everyone failed',
        context: {
          'room_id': roomId,
          'message_count': uniqueMessages.length,
          'current_uid': currentUid,
        },
      );
      rethrow;
    }
  }

  @action
  Future<void> toggleMessageReaction(
    ChatMessageModel message,
    String emoji,
  ) async {
    if (roomId == null || currentUid == null) return;
    if (message.status != MessageStatus.sent) return;

    final selectedEmoji = emoji.trim();
    if (selectedEmoji.isEmpty) return;

    final currentReaction = message.reactions[currentUid];
    final nextReaction =
        currentReaction == selectedEmoji ? null : selectedEmoji;

    try {
      await chatRepository.setMessageReaction(
        roomId: roomId!,
        messageId: message.id,
        uid: currentUid!,
        emoji: nextReaction,
      );
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Set chat message reaction failed',
        context: {
          'room_id': roomId,
          'message_id': message.id,
          'current_uid': currentUid,
          'emoji': selectedEmoji,
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
    if (room?.value == null) return;
    _resetUnreadTimer?.cancel();
    _resetUnreadTimer = Timer(const Duration(milliseconds: 600), _resetUnread);
  }

  // -----------------------
  // TYPING
  // -----------------------
  @action
  void onTypingChanged(String text) {
    if (roomId == null || currentUid == null) return;
    if (room?.value == null) return;

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
    if (room?.value == null) return;

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
    if (roomId != null && currentUid != null && room?.value != null) {
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
    _initialMessageLoadFallbackTimer?.cancel();
    _initialMessageLoadSubscription?.cancel();
    _initialMessageLoadSubscription = null;
    _initialMessageLoadFallbackTimer = null;
    _messageStatusDisposer?.call();
    _messageStatusDisposer = null;
    _deliveredMessageIds.clear();
    _readMessageIds.clear();
    _didCaptureUnreadDivider = false;
    roomId = null;
    targetUid = null;
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
