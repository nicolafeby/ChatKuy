import 'dart:io';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/helpers/image_saver_helper.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
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
          (snapshot) => snapshot.docs.map((doc) {
            return ChatRoomModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            });
          }).toList(),
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

          updates[messageId] = ChatMessageModel(
            id: existing.id,
            roomId: existing.roomId,
            senderId: existing.senderId,
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

        updates[messageId] = ChatMessageModel(
          id: messageId,
          roomId: roomId,
          senderId: data[MessageField.senderId] ?? '',
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

    final roomSnap = await roomRef.get();
    final roomData = roomSnap.data();
    if (roomData == null) {
      throw StateError('Chat room $roomId tidak ditemukan');
    }

    final participants =
        List<String>.from(roomData[ChatRoomField.participants] ?? const []);

    final targetUid = participants.firstWhere(
      (e) => e != uid,
      orElse: () => '',
    );
    if (targetUid.isEmpty) {
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

      final batch = firestore.batch();

      batch.set(messageRef, {
        MessageField.senderId: uid,
        MessageField.text: text,
        MessageField.imageUrl: uploadedImageUrl,
        MessageField.localImagePath: localPath,
        MessageField.videoUrl: uploadedVideoUrl,
        MessageField.localVideoPath: localVideo,
        MessageField.fileUrl: uploadedFileUrl,
        MessageField.localFilePath: resolvedLocalFilePath,
        MessageField.fileName: resolvedFileName,
        MessageField.fileSize: resolvedFileSize,
        MessageField.fileExtension: resolvedFileExtension,
        MessageField.contactName: contactName,
        MessageField.contactPhone: contactPhone,
        MessageField.audioUrl: uploadedAudioUrl,
        MessageField.localAudioPath: resolvedLocalAudioPath,
        MessageField.audioDurationSeconds: audioDurationSeconds,
        MessageField.createdAt: FieldValue.serverTimestamp(),
        MessageField.createdAtClient: createdAtClient,
        MessageField.clientMessageId: clientMessageId,
        MessageField.deliveredTo: <String, bool>{},
        MessageField.readBy: <String, bool>{},
        MessageField.deletedFor: <String, bool>{},
        MessageField.senderName: senderName,
        MessageField.type: type.name,
        MessageField.replyToMessageId: replyToMessage?.id,
        MessageField.replyToSenderId: replyToMessage?.senderId,
        MessageField.replyToSenderName: replyToSenderName,
        MessageField.replyToText: _replyPreviewText(replyToMessage),
        MessageField.replyToType: replyToMessage?.type.name,
      });

      batch.update(roomRef, {
        ChatRoomField.lastMessage: _resolveLastMessage(text, type),
        ChatRoomField.lastMessageAt: FieldValue.serverTimestamp(),
        ChatRoomField.lastSenderId: uid,
        '${ChatRoomField.unreadCount}.$uid': 0,
        '${ChatRoomField.unreadCount}.$targetUid': FieldValue.increment(1),
        ChatRoomField.imageUrl: uploadedImageUrl,
        ChatRoomField.type: type.name,
      });

      await batch.commit();
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

  Map<String, bool> _deletedForFromData(Map<String, dynamic> data) {
    return Map<String, bool>.from(data[MessageField.deletedFor] ?? {});
  }

  bool _isDeletedForCurrentUser(
    Map<String, bool> deletedFor,
    String? currentUid,
  ) {
    if (currentUid == null || currentUid.isEmpty) return false;
    return deletedFor[currentUid] == true;
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

    await roomRef.set({
      ChatRoomField.participants: [currentUid, targetUid],
      ChatRoomField.lastMessage: null,
      ChatRoomField.lastMessageAt: FieldValue.serverTimestamp(),
      ChatRoomField.lastSenderId: null,
      ChatRoomField.unreadCount: {
        currentUid: 0,
        targetUid: 0,
      },
    });

    return roomId;
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
    return _chatRoomsRef.doc(roomId).update({
      'typing.$uid': isTyping,
    });
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
        .update({
      '${MessageField.deliveredTo}.$uid': true,
    });
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
        .update({
      '${MessageField.readBy}.$uid': true,
    });
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
          .update({
        '${MessageField.deletedFor}.$uid': true,
      });
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    return _chatRoomsRef.doc(roomId).update({
      '${ChatRoomField.deletedMessagesFor}.$uid.$messageId': true,
    });
  }

  @override
  Future<void> resetUnread({
    required String roomId,
    required String uid,
  }) {
    return _chatRoomsRef.doc(roomId).update({
      '${ChatRoomField.unreadCount}.$uid': 0,
    });
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
