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
  // ROOM MESSAGES
  // -------------------------------
  // -------------------------------
  // WATCH MESSAGES
  // -------------------------------
  @override
  Stream<List<ChatMessageModel>> watchMessages({
    required String roomId,
  }) {
    return _chatRoomsRef
        .doc(roomId)
        .collection(FirestoreCollection.messages)
        .orderBy(MessageField.createdAtClient)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final createdAtServer = (data[MessageField.createdAt] as Timestamp?)?.toDate();

        final createdAtClient = (data[MessageField.createdAtClient] as Timestamp?)?.toDate() ??
            createdAtServer ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return ChatMessageModel(
          id: doc.id,
          senderId: (data[MessageField.senderId] as String).trim(),
          text: data[MessageField.text] as String,
          createdAt: createdAtServer ?? createdAtClient,
          createdAtClient: createdAtClient,
          deliveredTo: Map<String, bool>.from(
            data[MessageField.deliveredTo] ?? {},
          ),
          readBy: Map<String, bool>.from(
            data[MessageField.readBy] ?? {},
          ),
          status: doc.metadata.hasPendingWrites ? MessageStatus.pending : MessageStatus.sent,
        );
      }).toList();
    });
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
      MessageField.createdAtClient: DateTime.now(),

      // 🔥 WAJIB untuk status ala WhatsApp
      MessageField.deliveredTo: <String, bool>{},
      MessageField.readBy: <String, bool>{},
    });

    batch.update(roomRef, {
      ChatRoomField.lastMessage: text,
      ChatRoomField.lastMessageAt: FieldValue.serverTimestamp(),
      ChatRoomField.lastSenderId: uid,
      '${ChatRoomField.unreadCount}.$uid': 0,
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
  // MARK READ (✓✓ warna)
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
}
