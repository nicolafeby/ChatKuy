import 'dart:io';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/helpers/image_saver_helper.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';

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
  final Box<ChatMessageModel> _messageBox = Hive.box<ChatMessageModel>('chat_messages');

  CollectionReference<Map<String, dynamic>> get _chatRoomsRef => firestore.collection(FirebaseCollections.chatRooms);

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
    yield _getLocalMessages(roomId);

    yield* _chatRoomsRef
        .doc(roomId)
        .collection(FirestoreCollection.messages)
        .orderBy(MessageField.createdAtClient)
        .snapshots(includeMetadataChanges: true)
        .asyncMap((snapshot) async {
      final updates = <String, ChatMessageModel>{};

      for (final doc in snapshot.docs) {
        final messageId = doc.id;
        final existing = _messageBox.get(messageId);

        if (doc.metadata.hasPendingWrites) {
          continue;
        }

        if (existing != null) {
          final data = doc.data();

          final newDelivered = Map<String, bool>.from(data[MessageField.deliveredTo] ?? {});
          final newRead = Map<String, bool>.from(data[MessageField.readBy] ?? {});

          updates[messageId] = ChatMessageModel(
            id: existing.id,
            roomId: existing.roomId,
            senderId: existing.senderId,
            text: existing.text,
            imageUrl: existing.imageUrl,
            localImagePath: existing.localImagePath,
            type: existing.type,
            createdAt: existing.createdAt,
            createdAtClient: existing.createdAtClient,
            deliveredTo: newDelivered,
            readBy: newRead,
            status: existing.status == MessageStatus.pending ? MessageStatus.sent : existing.status,
          );

          continue;
        }

        final data = doc.data();

        updates[messageId] = ChatMessageModel(
          id: messageId,
          roomId: roomId,
          senderId: data[MessageField.senderId] ?? '',
          text: data[MessageField.text],
          imageUrl: data[MessageField.imageUrl],
          localImagePath: data[MessageField.localImagePath],
          type: data[MessageField.type] == 'image' ? MessageType.image : MessageType.text,
          createdAt: DateTime.now(),
          createdAtClient: DateTime.now(),
          deliveredTo: Map<String, bool>.from(data[MessageField.deliveredTo] ?? {}),
          readBy: Map<String, bool>.from(data[MessageField.readBy] ?? {}),
          status: MessageStatus.sent,
        );
      }

      if (updates.isNotEmpty) {
        await _messageBox.putAll(updates);
      }

      return _getLocalMessages(roomId);
    });
  }

  List<ChatMessageModel> _getLocalMessages(String roomId) {
    final messages = _messageBox.values.where((m) => m.roomId == roomId).toList();

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
    required MessageType type,
    String? localImagePath,
  }) async {
    final uid = auth.currentUser!.uid;

    final roomRef = _chatRoomsRef.doc(roomId);
    final messageRef = roomRef.collection(FirestoreCollection.messages).doc();

    final batch = firestore.batch();

    final userDoc = await firestore.collection(FirebaseCollections.users).doc(uid).get();
    final senderName = userDoc.data()?[FriendField.name] ?? 'Unknown';

    final roomSnap = await roomRef.get();
    final participants = List<String>.from(roomSnap.data()![ChatRoomField.participants]);

    final targetUid = participants.firstWhere((e) => e != uid);

    /// OPTIMISTIC LOCAL MESSAGE
    final localMessage = ChatMessageModel(
      id: messageRef.id,
      roomId: roomId,
      senderId: uid,
      text: text,
      imageUrl: imageUrl,
      type: type,
      createdAt: DateTime.now(),
      createdAtClient: DateTime.now(),
      deliveredTo: {},
      readBy: {},
      status: MessageStatus.pending,
      localImagePath: localImagePath,
    );

    await _messageBox.put(localMessage.id, localMessage);

    batch.set(messageRef, {
      MessageField.senderId: uid,
      MessageField.text: text,
      MessageField.imageUrl: imageUrl,
      MessageField.localImagePath: localImagePath,
      MessageField.createdAt: FieldValue.serverTimestamp(),
      MessageField.createdAtClient: DateTime.now(),
      MessageField.deliveredTo: <String, bool>{},
      MessageField.readBy: <String, bool>{},
      MessageField.senderName: senderName,
      MessageField.type: type.name,
    });

    batch.update(roomRef, {
      ChatRoomField.lastMessage: text,
      ChatRoomField.lastMessageAt: FieldValue.serverTimestamp(),
      ChatRoomField.lastSenderId: uid,
      '${ChatRoomField.unreadCount}.$uid': 0,
      '${ChatRoomField.unreadCount}.$targetUid': FieldValue.increment(1),
      ChatRoomField.imageUrl: imageUrl,
      ChatRoomField.type: type.name,
    });

    try {
      await batch.commit();
    } catch (e) {
      rethrow;
    }
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
    return _chatRoomsRef.doc(roomId).collection(FirestoreCollection.messages).doc(messageId).update({
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
    return _chatRoomsRef.doc(roomId).collection(FirestoreCollection.messages).doc(messageId).update({
      '${MessageField.readBy}.$uid': true,
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
    final localImagePath = await saveImageToLocal(imageFile: file, roomId: roomId);

    final ref = firebaseStorage
        .ref()
        .child(StorageCollection.chatImages)
        .child('${roomId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(file);

    final downloadUrl = await ref.getDownloadURL();

    final data = LocalImageModel(localImagePath: localImagePath, downloadUrl: downloadUrl);

    return data;
  }
}
