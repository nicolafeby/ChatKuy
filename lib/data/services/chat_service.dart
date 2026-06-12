import 'dart:io';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/helpers/image_saver_helper.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_message_update_model.dart';
import 'package:chatkuy/data/models/chat_message_write_model.dart';
import 'package:chatkuy/data/models/chat_room_message_update_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/models/chat_room_update_model.dart';
import 'package:chatkuy/data/models/chat_room_write_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/services/firestore_model_converters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

class ChatService implements ChatRepository {
  ChatService(
    this.auth,
    this.firestore,
    this.firebaseStorage,
  );

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  /// HIVE BOX
  final Box<ChatMessageModel> _messageBox =
      Hive.box<ChatMessageModel>('chat_messages');
  final Box<UserModel> _userBox = Hive.box<UserModel>('user_model');

  CollectionReference<Map<String, dynamic>> get _chatRoomsRef =>
      firestore.collection(FirebaseCollections.chatRooms);

  // -------------------------------
  // CHAT LIST
  // -------------------------------
  @override
  Stream<List<ChatRoomModel>> watchChatRooms({
    required String uid,
  }) {
    return _chatRoomsRef
        .where(ChatRoomField.participants, arrayContains: uid)
        .orderBy(ChatRoomField.lastMessageAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => !_isChatListDeletedForUser(doc.data(), uid))
              .map(FirestoreModelConverters.chatRoomFromSnapshot)
              .toList(),
        );
  }

  // -------------------------------
  // WATCH MESSAGES
  // -------------------------------
  @override
  Stream<List<ChatMessageModel>> watchMessages({
    required String roomId,
  }) async* {
    final currentUid = auth.currentUser?.uid;

    yield _getLocalMessages(roomId, currentUid: currentUid);

    yield* _chatRoomsRef
        .doc(roomId)
        .collection(FirestoreCollection.messages)
        .orderBy(MessageField.createdAtClient)
        .snapshots(includeMetadataChanges: true)
        .asyncMap((snapshot) async {
      final updates = <String, ChatMessageModel>{};

      final changedDocs = snapshot.docChanges
          .where((change) => change.type != DocumentChangeType.removed)
          .map((change) => change.doc)
          .toList();
      final docsToProcess = changedDocs.isEmpty ? snapshot.docs : changedDocs;

      for (final doc in docsToProcess) {
        final messageId = doc.id;
        final existing = _messageBox.get(messageId);
        final data = doc.data();
        if (data == null) continue;

        if (existing != null) {
          final newDelivered =
              Map<String, bool>.from(data[MessageField.deliveredTo] ?? {});
          final newRead =
              Map<String, bool>.from(data[MessageField.readBy] ?? {});
          final deletedFor = _deletedForFromData(data);
          final reactions = _reactionsFromData(data);

          updates[messageId] = ChatMessageModel(
            id: existing.id,
            roomId: existing.roomId,
            senderId: existing.senderId,
            senderName: existing.senderName ?? data[MessageField.senderName],
            text: existing.text,
            imageUrl: existing.imageUrl ?? data[MessageField.imageUrl],
            localImagePath: _existingFilePath(existing.localImagePath),
            videoUrl: existing.videoUrl ?? data[MessageField.videoUrl],
            localVideoPath: _existingFilePath(existing.localVideoPath),
            fileUrl: existing.fileUrl ?? data[MessageField.fileUrl],
            localFilePath: _existingFilePath(existing.localFilePath),
            fileName: existing.fileName ?? data[MessageField.fileName],
            fileSize: existing.fileSize ??
                (data[MessageField.fileSize] as num?)?.toInt(),
            fileExtension:
                existing.fileExtension ?? data[MessageField.fileExtension],
            contactName: existing.contactName ?? data[MessageField.contactName],
            contactPhone:
                existing.contactPhone ?? data[MessageField.contactPhone],
            audioUrl: existing.audioUrl ?? data[MessageField.audioUrl],
            localAudioPath: _existingFilePath(existing.localAudioPath),
            audioDurationSeconds:
                (data[MessageField.audioDurationSeconds] as num?)?.toInt() ??
                    existing.audioDurationSeconds,
            type: existing.type,
            createdAt: existing.createdAt,
            createdAtClient: existing.createdAtClient,
            clientMessageId:
                existing.clientMessageId ?? data[MessageField.clientMessageId],
            deliveredTo: newDelivered,
            readBy: newRead,
            status: existing.status == MessageStatus.pending
                ? MessageStatus.sent
                : existing.status,
            replyToMessageId: existing.replyToMessageId ??
                data[MessageField.replyToMessageId],
            replyToSenderId:
                existing.replyToSenderId ?? data[MessageField.replyToSenderId],
            replyToSenderName: existing.replyToSenderName ??
                data[MessageField.replyToSenderName],
            replyToText: existing.replyToText ?? data[MessageField.replyToText],
            replyToType: existing.replyToType ??
                _nullableMessageTypeFromString(data[MessageField.replyToType]),
            deletedFor: deletedFor,
            reactions: reactions,
            mentionedUserIds: _stringListFromData(
              data[MessageField.mentionedUserIds],
            ),
            mentionedUserNames: _stringListFromData(
              data[MessageField.mentionedUserNames],
            ),
            callId: existing.callId ?? data[MessageField.callId],
            callStatus: data[MessageField.callStatus] ?? existing.callStatus,
            callType: existing.callType ?? data[MessageField.callType],
            callDurationSeconds:
                (data[MessageField.callDurationSeconds] as num?)?.toInt() ??
                    existing.callDurationSeconds,
          );

          continue;
        }

        final deletedFor = _deletedForFromData(data);
        final reactions = _reactionsFromData(data);

        updates[messageId] = ChatMessageModel(
          id: messageId,
          roomId: roomId,
          senderId: data[MessageField.senderId] ?? '',
          senderName: data[MessageField.senderName],
          text: data[MessageField.text],
          imageUrl: data[MessageField.imageUrl],
          localImagePath: _existingFilePath(data[MessageField.localImagePath]),
          videoUrl: data[MessageField.videoUrl],
          localVideoPath: _existingFilePath(data[MessageField.localVideoPath]),
          fileUrl: data[MessageField.fileUrl],
          localFilePath: _existingFilePath(data[MessageField.localFilePath]),
          fileName: data[MessageField.fileName],
          fileSize: (data[MessageField.fileSize] as num?)?.toInt(),
          fileExtension: data[MessageField.fileExtension],
          contactName: data[MessageField.contactName],
          contactPhone: data[MessageField.contactPhone],
          audioUrl: data[MessageField.audioUrl],
          localAudioPath: _existingFilePath(data[MessageField.localAudioPath]),
          audioDurationSeconds:
              (data[MessageField.audioDurationSeconds] as num?)?.toInt(),
          type: _messageTypeFromString(data[MessageField.type]),
          createdAt: _dateFromFirestore(data[MessageField.createdAt]) ??
              _dateFromFirestore(data[MessageField.createdAtClient]) ??
              DateTime.now(),
          createdAtClient:
              _dateFromFirestore(data[MessageField.createdAtClient]) ??
                  DateTime.now(),
          clientMessageId: data[MessageField.clientMessageId],
          deliveredTo:
              Map<String, bool>.from(data[MessageField.deliveredTo] ?? {}),
          readBy: Map<String, bool>.from(data[MessageField.readBy] ?? {}),
          status: MessageStatus.sent,
          replyToMessageId: data[MessageField.replyToMessageId],
          replyToSenderId: data[MessageField.replyToSenderId],
          replyToSenderName: data[MessageField.replyToSenderName],
          replyToText: data[MessageField.replyToText],
          replyToType:
              _nullableMessageTypeFromString(data[MessageField.replyToType]),
          deletedFor: deletedFor,
          reactions: reactions,
          mentionedUserIds: _stringListFromData(
            data[MessageField.mentionedUserIds],
          ),
          mentionedUserNames: _stringListFromData(
            data[MessageField.mentionedUserNames],
          ),
          callId: data[MessageField.callId],
          callStatus: data[MessageField.callStatus],
          callType: data[MessageField.callType],
          callDurationSeconds:
              (data[MessageField.callDurationSeconds] as num?)?.toInt(),
        );
      }

      if (updates.isNotEmpty) {
        await _messageBox.putAll(updates);
      }

      final roomDeletedMessageIds = await _getRoomDeletedMessageIdsForUser(
        roomId: roomId,
        uid: currentUid,
      );

      return _getLocalMessages(
        roomId,
        currentUid: currentUid,
        roomDeletedMessageIds: roomDeletedMessageIds,
      );
    });
  }

  List<ChatMessageModel> _getLocalMessages(
    String roomId, {
    String? currentUid,
    Set<String> roomDeletedMessageIds = const {},
  }) {
    final messages = _messageBox.values
        .where(
          (m) =>
              m.roomId == roomId &&
              !_isDeletedForCurrentUser(m.deletedFor, currentUid) &&
              !roomDeletedMessageIds.contains(m.id),
        )
        .toList();

    messages.sort(
      (a, b) => a.createdAtClient.compareTo(b.createdAtClient),
    );

    return messages;
  }

  // -------------------------------
  // SEND MESSAGE
  // -------------------------------
  @override
  Future<void> sendMessage({
    required String roomId,
    String? targetUid,
    String? text,
    String? imageUrl,
    File? imageFile,
    String? videoUrl,
    File? videoFile,
    String? fileUrl,
    File? file,
    String? fileName,
    int? fileSize,
    String? fileExtension,
    String? contactName,
    String? contactPhone,
    String? audioUrl,
    File? audioFile,
    String? localAudioPath,
    int? audioDurationSeconds,
    required MessageType type,
    String? clientMessageId,
    String? localImagePath,
    String? localVideoPath,
    String? localFilePath,
    ChatMessageModel? replyToMessage,
    String? replyToSenderName,
    List<String> mentionedUserIds = const [],
    List<String> mentionedUserNames = const [],
    void Function(int progress)? onUploadProgress,
  }) async {
    final uid = auth.currentUser!.uid;

    final roomRef = _chatRoomsRef.doc(roomId);
    final messagesRef = roomRef.collection(FirestoreCollection.messages);
    final messageRef = clientMessageId == null
        ? messagesRef.doc()
        : messagesRef.doc(clientMessageId);

    final userDoc =
        await firestore.collection(FirebaseCollections.users).doc(uid).get();
    final senderName = userDoc.data()?[FriendField.name] ?? 'Unknown';

    final roomSnap = await _getRoomIfReadable(
      roomRef: roomRef,
      targetUid: targetUid,
    );
    final roomData = roomSnap?.data();
    final roomExists = roomSnap?.exists == true && roomData != null;
    final participants = roomExists
        ? List<String>.from(roomData[ChatRoomField.participants] ?? const [])
        : _draftDirectRoomParticipants(
            roomId: roomId,
            currentUid: uid,
            targetUid: targetUid,
          );

    final recipientUids = participants.where((e) => e != uid).toList();
    if (recipientUids.isEmpty) {
      throw StateError('Chat room $roomId tidak memiliki penerima pesan');
    }
    final createdAtClient = DateTime.now();
    final localPath = localImagePath ??
        (imageFile != null
            ? await saveImageToLocal(imageFile: imageFile, roomId: roomId)
            : null);
    final localVideo = localVideoPath ??
        (videoFile != null
            ? await saveVideoToLocal(videoFile: videoFile, roomId: roomId)
            : null);
    final resolvedLocalFilePath = localFilePath ??
        (file != null
            ? await saveFileToLocal(file: file, roomId: roomId)
            : null);
    final resolvedFileName =
        fileName ?? (file == null ? null : p.basename(file.path));
    final resolvedFileSize =
        fileSize ?? (file == null ? null : await file.length());
    final resolvedFileExtension = fileExtension ??
        (resolvedFileName == null
            ? null
            : p
                .extension(resolvedFileName)
                .replaceFirst('.', '')
                .toUpperCase());
    final resolvedLocalAudioPath = localAudioPath ??
        (audioFile != null
            ? await saveAudioToLocal(audioFile: audioFile, roomId: roomId)
            : null);

    /// OPTIMISTIC LOCAL MESSAGE
    final localMessage = ChatMessageModel(
      id: messageRef.id,
      roomId: roomId,
      senderId: uid,
      senderName: senderName,
      text: text,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      fileUrl: fileUrl,
      localFilePath: resolvedLocalFilePath,
      fileName: resolvedFileName,
      fileSize: resolvedFileSize,
      fileExtension: resolvedFileExtension,
      contactName: contactName,
      contactPhone: contactPhone,
      audioUrl: audioUrl,
      localAudioPath: resolvedLocalAudioPath,
      audioDurationSeconds: audioDurationSeconds,
      type: type,
      createdAt: createdAtClient,
      createdAtClient: createdAtClient,
      clientMessageId: clientMessageId,
      deliveredTo: {},
      readBy: {},
      status: MessageStatus.pending,
      localImagePath: localPath,
      localVideoPath: localVideo,
      replyToMessageId: replyToMessage?.id,
      replyToSenderId: replyToMessage?.senderId,
      replyToSenderName: replyToSenderName,
      replyToText: _replyPreviewText(replyToMessage),
      replyToType: replyToMessage?.type,
      mentionedUserIds: mentionedUserIds,
      mentionedUserNames: mentionedUserNames,
    );

    await _messageBox.put(localMessage.id, localMessage);

    try {
      String? uploadedImageUrl = imageUrl;
      String? uploadedVideoUrl = videoUrl;
      String? uploadedFileUrl = fileUrl;
      String? uploadedAudioUrl = audioUrl;

      if (imageFile != null) {
        final ref = firebaseStorage
            .ref()
            .child(StorageCollection.chatImages)
            .child(imageNameFormat(roomId, imageFile));

        final uploadTask = ref.putFile(imageFile);

        await for (final snapshot in uploadTask.snapshotEvents) {
          final totalBytes = snapshot.totalBytes;

          if (totalBytes > 0) {
            final progress = ((snapshot.bytesTransferred / totalBytes) * 100)
                .round()
                .clamp(0, 100);
            onUploadProgress?.call(progress);
          }
        }

        onUploadProgress?.call(100);
        uploadedImageUrl = await ref.getDownloadURL();

        await _messageBox.put(
          localMessage.id,
          localMessage.copyWith(imageUrl: uploadedImageUrl),
        );
      }

      if (videoFile != null) {
        final ref = firebaseStorage
            .ref()
            .child(StorageCollection.chatVideos)
            .child(mediaNameFormat(roomId, videoFile));

        final uploadTask = ref.putFile(videoFile);

        await for (final snapshot in uploadTask.snapshotEvents) {
          final totalBytes = snapshot.totalBytes;

          if (totalBytes > 0) {
            final progress = ((snapshot.bytesTransferred / totalBytes) * 100)
                .round()
                .clamp(0, 100);
            onUploadProgress?.call(progress);
          }
        }

        onUploadProgress?.call(100);
        uploadedVideoUrl = await ref.getDownloadURL();

        await _messageBox.put(
          localMessage.id,
          localMessage.copyWith(videoUrl: uploadedVideoUrl),
        );
      }

      if (file != null) {
        final ref = firebaseStorage
            .ref()
            .child(StorageCollection.chatFiles)
            .child(mediaNameFormat(roomId, file));

        final uploadTask = ref.putFile(file);

        await for (final snapshot in uploadTask.snapshotEvents) {
          final totalBytes = snapshot.totalBytes;

          if (totalBytes > 0) {
            final progress = ((snapshot.bytesTransferred / totalBytes) * 100)
                .round()
                .clamp(0, 100);
            onUploadProgress?.call(progress);
          }
        }

        onUploadProgress?.call(100);
        uploadedFileUrl = await ref.getDownloadURL();

        await _messageBox.put(
          localMessage.id,
          localMessage.copyWith(fileUrl: uploadedFileUrl),
        );
      }

      if (audioFile != null) {
        final ref = firebaseStorage
            .ref()
            .child(StorageCollection.chatAudios)
            .child(mediaNameFormat(roomId, audioFile));

        final uploadTask = ref.putFile(audioFile);

        await for (final snapshot in uploadTask.snapshotEvents) {
          final totalBytes = snapshot.totalBytes;

          if (totalBytes > 0) {
            final progress = ((snapshot.bytesTransferred / totalBytes) * 100)
                .round()
                .clamp(0, 100);
            onUploadProgress?.call(progress);
          }
        }

        onUploadProgress?.call(100);
        uploadedAudioUrl = await ref.getDownloadURL();

        await _messageBox.put(
          localMessage.id,
          localMessage.copyWith(audioUrl: uploadedAudioUrl),
        );
      }

      final messageData = ChatMessageWriteModel(
        senderId: uid,
        text: text,
        imageUrl: uploadedImageUrl,
        localImagePath: localPath,
        videoUrl: uploadedVideoUrl,
        localVideoPath: localVideo,
        fileUrl: uploadedFileUrl,
        localFilePath: resolvedLocalFilePath,
        fileName: resolvedFileName,
        fileSize: resolvedFileSize,
        fileExtension: resolvedFileExtension,
        contactName: contactName,
        contactPhone: contactPhone,
        audioUrl: uploadedAudioUrl,
        localAudioPath: resolvedLocalAudioPath,
        audioDurationSeconds: audioDurationSeconds,
        createdAtClient: createdAtClient,
        clientMessageId: clientMessageId,
        senderName: senderName,
        type: type.name,
        replyToMessageId: replyToMessage?.id,
        replyToSenderId: replyToMessage?.senderId,
        replyToSenderName: replyToSenderName,
        replyToText: _replyPreviewText(replyToMessage),
        replyToType: replyToMessage?.type.name,
        mentionedUserIds: mentionedUserIds,
        mentionedUserNames: mentionedUserNames,
      ).toFirestoreJson();

      final roomUpdates = ChatRoomMessageUpdateModel(
        lastMessage: _resolveLastMessage(text, type),
        senderId: uid,
        imageUrl: uploadedImageUrl,
        type: type.name,
        participants: roomExists ? null : participants,
        recipientUids: recipientUids,
      ).toFirestoreJson();

      await _commitMessageAndRoom(
        messageRef: messageRef,
        roomRef: roomRef,
        messageData: messageData,
        roomUpdates: roomUpdates,
        canRetryWithoutParticipants: !roomExists && targetUid != null,
      );
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Chat service sendMessage failed',
        context: {
          'room_id': roomId,
          'uid': uid,
          'message_type': type.name,
          'has_image': imageFile != null,
          'has_video': videoFile != null,
          'has_file': file != null,
          'has_audio': audioFile != null,
          'has_text': text?.trim().isNotEmpty == true,
        },
      );
      await _messageBox.put(
        localMessage.id,
        localMessage.copyWith(status: MessageStatus.failed),
      );
      rethrow;
    }
  }

  String _fallbackLastMessage(MessageType type) {
    if (type == MessageType.image) return 'Foto';
    if (type == MessageType.video) return 'Video';
    if (type == MessageType.call) return 'Panggilan';
    if (type == MessageType.file) return 'Dokumen';
    if (type == MessageType.contact) return 'Kontak';
    if (type == MessageType.audio) return 'Pesan suara';
    return '';
  }

  String _resolveLastMessage(String? text, MessageType type) {
    final messageText = text?.trim();
    if (messageText != null && messageText.isNotEmpty) return messageText;
    return _fallbackLastMessage(type);
  }

  MessageType _messageTypeFromString(dynamic value) {
    if (value == MessageType.image.name) return MessageType.image;
    if (value == MessageType.video.name) return MessageType.video;
    if (value == MessageType.call.name) return MessageType.call;
    if (value == MessageType.file.name) return MessageType.file;
    if (value == MessageType.contact.name) return MessageType.contact;
    if (value == MessageType.audio.name) return MessageType.audio;
    return MessageType.text;
  }

  MessageType? _nullableMessageTypeFromString(dynamic value) {
    if (value == null) return null;
    return _messageTypeFromString(value);
  }

  List<String> _draftDirectRoomParticipants({
    required String roomId,
    required String currentUid,
    required String? targetUid,
  }) {
    final cleanTargetUid = targetUid?.trim();
    if (cleanTargetUid == null || cleanTargetUid.isEmpty) {
      throw StateError(
        'Chat room $roomId belum ada dan targetUid tidak tersedia',
      );
    }

    return [currentUid, cleanTargetUid];
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getRoomIfReadable({
    required DocumentReference<Map<String, dynamic>> roomRef,
    required String? targetUid,
  }) async {
    try {
      return await roomRef.get();
    } on FirebaseException catch (e) {
      final cleanTargetUid = targetUid?.trim();
      final canCreateDraftDirectRoom =
          cleanTargetUid != null && cleanTargetUid.isNotEmpty;

      if (e.code == 'permission-denied' && canCreateDraftDirectRoom) {
        return null;
      }

      rethrow;
    }
  }

  Future<void> _commitMessageAndRoom({
    required DocumentReference<Map<String, dynamic>> messageRef,
    required DocumentReference<Map<String, dynamic>> roomRef,
    required Map<String, Object?> messageData,
    required Map<String, dynamic> roomUpdates,
    required bool canRetryWithoutParticipants,
  }) async {
    try {
      await _commitMessageAndRoomBatch(
        messageRef: messageRef,
        roomRef: roomRef,
        messageData: messageData,
        roomUpdates: roomUpdates,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied' || !canRetryWithoutParticipants) {
        rethrow;
      }

      final retryRoomUpdates = Map<String, dynamic>.from(roomUpdates)
        ..remove(ChatRoomField.participants);

      await _commitMessageAndRoomBatch(
        messageRef: messageRef,
        roomRef: roomRef,
        messageData: messageData,
        roomUpdates: retryRoomUpdates,
      );
    }
  }

  Future<void> _commitMessageAndRoomBatch({
    required DocumentReference<Map<String, dynamic>> messageRef,
    required DocumentReference<Map<String, dynamic>> roomRef,
    required Map<String, Object?> messageData,
    required Map<String, dynamic> roomUpdates,
  }) async {
    final batch = firestore.batch();

    batch.set(messageRef, messageData);
    batch.set(roomRef, roomUpdates, SetOptions(merge: true));

    await batch.commit();
  }

  Map<String, bool> _deletedForFromData(Map<String, dynamic> data) {
    return Map<String, bool>.from(data[MessageField.deletedFor] ?? {});
  }

  Map<String, String> _reactionsFromData(Map<String, dynamic> data) {
    return Map<String, String>.from(data[MessageField.reactions] ?? {});
  }

  List<String> _stringListFromData(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  bool _isDeletedForCurrentUser(
    Map<String, bool> deletedFor,
    String? currentUid,
  ) {
    if (currentUid == null || currentUid.isEmpty) return false;
    return deletedFor[currentUid] == true;
  }

  bool _isChatListDeletedForUser(Map<String, dynamic> data, String uid) {
    final deletedChatListFor = Map<String, dynamic>.from(
      data[ChatRoomField.deletedChatListFor] ?? {},
    );
    return deletedChatListFor[uid] == true;
  }

  Future<Set<String>> _getRoomDeletedMessageIdsForUser({
    required String roomId,
    required String? uid,
  }) async {
    if (uid == null || uid.isEmpty) return {};

    try {
      final roomSnap = await _chatRoomsRef.doc(roomId).get();
      final roomData = roomSnap.data();
      final deletedMessagesFor = Map<String, dynamic>.from(
        roomData?[ChatRoomField.deletedMessagesFor] ?? {},
      );
      final deletedMessagesById = Map<String, dynamic>.from(
        deletedMessagesFor[uid] ?? {},
      );

      return deletedMessagesById.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  String? _replyPreviewText(ChatMessageModel? message) {
    if (message == null) return null;

    final messageText = message.text?.trim();
    if (messageText != null && messageText.isNotEmpty) return messageText;

    return _fallbackLastMessage(message.type);
  }

  String? _existingFilePath(dynamic path) {
    if (path is! String || path.isEmpty) return null;
    return File(path).existsSync() ? path : null;
  }

  DateTime? _dateFromFirestore(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  // -------------------------------
  // CREATE / GET ROOM
  // -------------------------------
  String buildRoomId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  @override
  String directRoomId({
    required String currentUid,
    required String targetUid,
  }) {
    return buildRoomId(currentUid, targetUid);
  }

  @override
  Future<String> createOrGetRoom({
    required String currentUid,
    required String targetUid,
  }) async {
    final roomId = buildRoomId(currentUid, targetUid);
    final roomRef = _chatRoomsRef.doc(roomId);

    final snapshot = await roomRef.get();
    if (snapshot.exists) {
      return roomId;
    }

    await roomRef.set(
      ChatRoomWriteModel.directRoom(
        currentUid: currentUid,
        targetUid: targetUid,
      ).toFirestoreJson(),
    );

    return roomId;
  }

  @override
  Future<String> createGroupRoom({
    required String currentUid,
    required String name,
    required List<String> memberUids,
    String? photoUrl,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Nama grup wajib diisi');
    }

    final participants = <String>{currentUid, ...memberUids}.toList();
    if (participants.length < 2) {
      throw ArgumentError('Grup membutuhkan minimal 2 member');
    }

    final roomRef = _chatRoomsRef.doc();
    await roomRef.set(
      ChatRoomWriteModel.groupRoom(
        currentUid: currentUid,
        name: cleanName,
        participants: participants,
        photoUrl: photoUrl,
      ).toFirestoreJson(),
    );

    return roomRef.id;
  }

  @override
  Stream<ChatRoomModel> watchRoom({required String roomId}) {
    return _chatRoomsRef
        .doc(roomId)
        .snapshots()
        .where((doc) => doc.exists && doc.data() != null)
        .map(FirestoreModelConverters.chatRoomFromSnapshot);
  }

  @override
  Stream<List<UserModel>> watchGroupMembers({required String roomId}) async* {
    List<UserModel>? lastEmitted;

    await for (final room in watchRoom(roomId: roomId)) {
      if (!room.isGroup || room.participants.isEmpty) {
        lastEmitted = const <UserModel>[];
        yield lastEmitted;
        continue;
      }

      final cachedUsers = _cachedUsersFor(room.participants);
      if (cachedUsers.isNotEmpty && !_sameUserList(lastEmitted, cachedUsers)) {
        lastEmitted = cachedUsers;
        yield cachedUsers;
      }

      final remoteUsers = await _fetchUsersByIds(room.participants);
      if (remoteUsers.isNotEmpty) {
        await _userBox.putAll({
          for (final user in remoteUsers) user.id: user,
        });
      }

      if (!_sameUserList(lastEmitted, remoteUsers)) {
        lastEmitted = remoteUsers;
        yield remoteUsers;
      }
    }
  }

  List<UserModel> _cachedUsersFor(List<String> participantIds) {
    final users = participantIds
        .map(_userBox.get)
        .whereType<UserModel>()
        .where((user) => user.id.isNotEmpty)
        .toList();

    return _sortUsersByParticipantOrder(users, participantIds);
  }

  Future<List<UserModel>> _fetchUsersByIds(List<String> userIds) async {
    final users = <UserModel>[];
    for (var i = 0; i < userIds.length; i += 10) {
      final chunk = userIds.skip(i).take(10).toList();
      final snapshot = await firestore
          .collection(FirebaseCollections.users)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      users.addAll(
        snapshot.docs.map(FirestoreModelConverters.userFromSnapshot),
      );
    }

    return _sortUsersByParticipantOrder(users, userIds);
  }

  List<UserModel> _sortUsersByParticipantOrder(
    List<UserModel> users,
    List<String> participantIds,
  ) {
    final indexByUid = {
      for (var i = 0; i < participantIds.length; i++) participantIds[i]: i,
    };

    return List<UserModel>.of(users)
      ..sort((a, b) {
        return (indexByUid[a.id] ?? 0).compareTo(indexByUid[b.id] ?? 0);
      });
  }

  bool _sameUserList(List<UserModel>? a, List<UserModel> b) {
    if (a == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.name != right.name ||
          left.username != right.username ||
          left.photoUrl != right.photoUrl) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> inviteGroupMembers({
    required String roomId,
    required String adminUid,
    required List<String> memberUids,
  }) async {
    final cleanMemberUids = memberUids.toSet().toList();
    if (cleanMemberUids.isEmpty) return;

    final roomRef = _chatRoomsRef.doc(roomId);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      final data = snapshot.data();
      _assertGroupAdmin(data, adminUid);

      final participants =
          _stringListFromData(data?[ChatRoomField.participants]);
      final newMembers =
          cleanMemberUids.where((uid) => !participants.contains(uid)).toList();
      if (newMembers.isEmpty) return;

      transaction.update(
        roomRef,
        ChatRoomUpdateModel.inviteMembers(newMembers).toFirestoreJson(),
      );
    });
  }

  @override
  Future<void> promoteGroupAdmin({
    required String roomId,
    required String adminUid,
    required String memberUid,
  }) async {
    final roomRef = _chatRoomsRef.doc(roomId);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      final data = snapshot.data();
      _assertGroupAdmin(data, adminUid);

      final participants =
          _stringListFromData(data?[ChatRoomField.participants]);
      if (!participants.contains(memberUid)) {
        throw StateError('Member belum bergabung di grup');
      }

      transaction.update(
        roomRef,
        ChatRoomUpdateModel.promoteAdmin(memberUid).toFirestoreJson(),
      );
    });
  }

  @override
  Future<void> removeGroupMember({
    required String roomId,
    required String adminUid,
    required String memberUid,
  }) async {
    final roomRef = _chatRoomsRef.doc(roomId);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      final data = snapshot.data();
      _assertGroupAdmin(data, adminUid);

      final participants =
          _stringListFromData(data?[ChatRoomField.participants]);
      if (!participants.contains(memberUid)) return;
      if (participants.length <= 2) {
        throw StateError('Grup membutuhkan minimal 2 member');
      }

      transaction.update(
        roomRef,
        ChatRoomUpdateModel.removeMember(memberUid).toFirestoreJson(),
      );
    });
  }

  @override
  Future<void> updateGroupInfo({
    required String roomId,
    required String adminUid,
    String? name,
    String? photoUrl,
  }) async {
    final cleanName = name?.trim();
    final updates = ChatRoomUpdateModel.groupInfo(
      name: cleanName,
      photoUrl: photoUrl,
    ).toFirestoreJson();
    if (updates.isEmpty) return;

    final roomRef = _chatRoomsRef.doc(roomId);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      _assertGroupAdmin(snapshot.data(), adminUid);
      transaction.update(roomRef, updates);
    });
  }

  void _assertGroupAdmin(Map<String, dynamic>? data, String uid) {
    if (data == null) {
      throw StateError('Grup tidak ditemukan');
    }

    final isGroup = data[ChatRoomField.isGroup] == true;
    final admins = _stringListFromData(data[ChatRoomField.admins]);
    if (!isGroup || !admins.contains(uid)) {
      throw StateError('Hanya admin grup yang dapat melakukan aksi ini');
    }
  }

  @override
  Stream<Map<String, bool>> watchTyping({
    required String roomId,
  }) {
    return _chatRoomsRef.doc(roomId).snapshots().map((doc) {
      final data = doc.data();
      final typing = data?['typing'];
      if (typing is Map) {
        return typing.map(
          (k, v) => MapEntry(k.toString(), v == true),
        );
      }
      return <String, bool>{};
    });
  }

  @override
  Future<void> setTyping({
    required String roomId,
    required String uid,
    required bool isTyping,
  }) {
    return _chatRoomsRef.doc(roomId).update(
        ChatRoomUpdateModel.typing(uid: uid, isTyping: isTyping)
            .toFirestoreJson());
  }

  // -------------------------------
  // MARK DELIVERED (✓✓ abu)
  // -------------------------------
  @override
  Future<void> markDelivered({
    required String roomId,
    required String messageId,
    required String uid,
  }) {
    return _chatRoomsRef
        .doc(roomId)
        .collection(FirestoreCollection.messages)
        .doc(messageId)
        .update(ChatMessageUpdateModel.delivered(uid).toFirestoreJson());
  }

  // -------------------------------
  // MARK READ
  // -------------------------------
  @override
  Future<void> markRead({
    required String roomId,
    required String messageId,
    required String uid,
  }) {
    return _chatRoomsRef
        .doc(roomId)
        .collection(FirestoreCollection.messages)
        .doc(messageId)
        .update(ChatMessageUpdateModel.read(uid).toFirestoreJson());
  }

  @override
  Future<void> deleteMessageForMe({
    required String roomId,
    required String messageId,
    required String uid,
  }) async {
    final existing = _messageBox.get(messageId);
    if (existing != null) {
      await _messageBox.put(
        messageId,
        existing.copyWith(
          deletedFor: {
            ...existing.deletedFor,
            uid: true,
          },
        ),
      );
    }

    if (existing != null && existing.status != MessageStatus.sent) return;

    try {
      await _chatRoomsRef
          .doc(roomId)
          .collection(FirestoreCollection.messages)
          .doc(messageId)
          .update(ChatMessageUpdateModel.deletedFor(uid).toFirestoreJson());
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    return _chatRoomsRef.doc(roomId).update(
          ChatRoomUpdateModel.deletedMessageFor(
            uid: uid,
            messageId: messageId,
          ).toFirestoreJson(),
        );
  }

  @override
  Future<void> setMessageReaction({
    required String roomId,
    required String messageId,
    required String uid,
    required String? emoji,
  }) async {
    final existing = _messageBox.get(messageId);
    final previousReactions =
        existing == null ? null : Map<String, String>.from(existing.reactions);

    if (existing != null) {
      final reactions = Map<String, String>.from(previousReactions!);
      if (emoji == null || emoji.isEmpty) {
        reactions.remove(uid);
      } else {
        reactions[uid] = emoji;
      }

      await _messageBox.put(
        messageId,
        existing.copyWith(reactions: reactions),
      );

      if (existing.status != MessageStatus.sent) return;
    }

    try {
      return await _chatRoomsRef
          .doc(roomId)
          .collection(FirestoreCollection.messages)
          .doc(messageId)
          .update(ChatMessageUpdateModel.reaction(uid: uid, emoji: emoji)
              .toFirestoreJson());
    } on FirebaseException catch (e) {
      if (existing != null && previousReactions != null) {
        await _messageBox.put(
          messageId,
          existing.copyWith(reactions: previousReactions),
        );
      }

      if (e.code == 'permission-denied') return;
      rethrow;
    }
  }

  @override
  Future<void> resetUnread({
    required String roomId,
    required String uid,
  }) {
    return _chatRoomsRef
        .doc(roomId)
        .update(ChatRoomUpdateModel.resetUnread(uid).toFirestoreJson());
  }

  // -------------------------------
  // UPLOAD IMAGE
  // -------------------------------
  @override
  Future<LocalImageModel> uploadImage({
    required File file,
    required String roomId,
  }) async {
    final localImagePath =
        await saveImageToLocal(imageFile: file, roomId: roomId);

    final ref = firebaseStorage
        .ref()
        .child(StorageCollection.chatImages)
        .child(imageNameFormat(roomId, file));

    await ref.putFile(file);

    final downloadUrl = await ref.getDownloadURL();

    final data = LocalImageModel(
      localImagePath: localImagePath,
      downloadUrl: downloadUrl,
    );

    return data;
  }
}
