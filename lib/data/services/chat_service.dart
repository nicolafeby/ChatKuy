import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService implements ChatRepository {
  ChatService(this.auth, this.firestore);

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _chatRoomsRef => firestore.collection(FirestoreCollection.chatRooms);

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
  // ROOM MESSAGES
  // -------------------------------
  @override
  Stream<List<ChatMessageModel>> watchMessages({
    required String roomId,
  }) {
    return _chatRoomsRef
        .doc(roomId)
        .collection(FirestoreCollection.messages)
        .orderBy(MessageField.createdAt)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return ChatMessageModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            });
          }).toList(),
        );
  }

  // -------------------------------
  // SEND MESSAGE
  // -------------------------------
  @override
  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final uid = auth.currentUser!.uid;

    final roomRef = _chatRoomsRef.doc(roomId);
    final messageRef = roomRef.collection(FirestoreCollection.messages).doc();

    final batch = firestore.batch();

    batch.set(messageRef, {
      MessageField.senderId: uid,
      MessageField.text: text,
      MessageField.createdAt: FieldValue.serverTimestamp(),
    });

    batch.update(roomRef, {
      ChatRoomField.lastMessage: text,
      ChatRoomField.lastMessageAt: FieldValue.serverTimestamp(),
      ChatRoomField.lastSenderId: uid,
      '${ChatRoomField.unreadCount}.$uid': 0,
    });

    await batch.commit();
  }

  // -------------------------------
  // CREATE / GET ROOM
  // -------------------------------
  @override
  Future<String> createOrGetRoom({
    required String currentUid,
    required String targetUid,
  }) async {
    final snapshot = await _chatRoomsRef
        .where(ChatRoomField.participants, arrayContains: currentUid)
        .orderBy(ChatRoomField.lastMessageAt, descending: true)
        .get();

    for (final doc in snapshot.docs) {
      final participants = List<String>.from(doc[ChatRoomField.participants]);
      if (participants.contains(targetUid)) {
        return doc.id;
      }
    }

    final roomRef = _chatRoomsRef.doc();

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

    return roomRef.id;
  }

  // -------------------------------
  // MARK AS READ
  // -------------------------------
  @override
  Future<void> markAsRead({
    required String roomId,
    required String uid,
  }) async {
    await _chatRoomsRef.doc(roomId).update({
      '${ChatRoomField.unreadCount}.$uid': 0,
    });
  }
}
