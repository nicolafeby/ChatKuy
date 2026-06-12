import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/models/request_friend_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreModelConverters {
  FirestoreModelConverters._();

  static CollectionReference<UserModel> usersRef(FirebaseFirestore firestore) {
    return firestore.collection(FirebaseCollections.users).withConverter(
          fromFirestore: (snapshot, _) => userFromSnapshot(snapshot),
          toFirestore: (user, _) => user.toJson(),
        );
  }

  static CollectionReference<ChatRoomModel> chatRoomsRef(
    FirebaseFirestore firestore,
  ) {
    return firestore.collection(FirebaseCollections.chatRooms).withConverter(
          fromFirestore: (snapshot, _) => chatRoomFromSnapshot(snapshot),
          toFirestore: (room, _) => room.toJson(),
        );
  }

  static CollectionReference<ChatMessageModel> messagesRef({
    required FirebaseFirestore firestore,
    required String roomId,
  }) {
    return firestore
        .collection(FirestorePaths.chatMessages(roomId))
        .withConverter(
          fromFirestore: (snapshot, _) => chatMessageFromSnapshot(
            snapshot,
            roomId: roomId,
          ),
          toFirestore: (message, _) => message.toJson(),
        );
  }

  static CollectionReference<FriendRequestModel> incomingFriendRequestsRef({
    required FirebaseFirestore firestore,
    required String uid,
  }) {
    return firestore
        .collection(FirestorePaths.userFriendRequests(uid))
        .withConverter(
          fromFirestore: (snapshot, _) => friendRequestFromSnapshot(snapshot),
          toFirestore: (request, _) => request.toJson(),
        );
  }

  static CollectionReference<FriendRequestModel> outgoingFriendRequestsRef({
    required FirebaseFirestore firestore,
    required String uid,
  }) {
    return firestore
        .doc(FirestorePaths.user(uid))
        .collection(FirestoreCollection.outgoingFriendRequests)
        .withConverter(
          fromFirestore: (snapshot, _) => friendRequestFromSnapshot(snapshot),
          toFirestore: (request, _) => request.toJson(),
        );
  }

  static UserModel userFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('User document ${snapshot.id} has no data');
    }

    return UserModel.fromJson({
      ..._normalizeUserDates(data),
      'id': snapshot.id,
    });
  }

  static ChatRoomModel chatRoomFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Chat room document ${snapshot.id} has no data');
    }

    return ChatRoomModel.fromJson({
      'id': snapshot.id,
      ...data,
    });
  }

  static ChatMessageModel chatMessageFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String roomId,
  }) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Message document ${snapshot.id} has no data');
    }

    return ChatMessageModel.fromJson({
      'id': snapshot.id,
      'roomId': roomId,
      ..._normalizeMessageJson(data),
    });
  }

  static FriendRequestModel friendRequestFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Friend request document ${snapshot.id} has no data');
    }

    return FriendRequestModel.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  static Map<String, dynamic> _normalizeUserDates(Map<String, dynamic> data) {
    return {
      ...data,
      'lastOnlineAt': _dateValueForGeneratedJson(data['lastOnlineAt']),
      'birthDate': _dateValueForGeneratedJson(data['birthDate']),
    };
  }

  static Map<String, dynamic> _normalizeMessageJson(Map<String, dynamic> data) {
    return {
      ...data,
      'senderId': data[MessageField.senderId] ?? '',
      'type': data[MessageField.type] ?? 'text',
      'createdAt': data[MessageField.createdAt] ??
          data[MessageField.createdAtClient] ??
          DateTime.now(),
      'createdAtClient': data[MessageField.createdAtClient] ?? DateTime.now(),
      'deliveredTo': data[MessageField.deliveredTo] ?? <String, bool>{},
      'readBy': data[MessageField.readBy] ?? <String, bool>{},
      'deletedFor': data[MessageField.deletedFor] ?? <String, bool>{},
      'mentionedUserIds': data[MessageField.mentionedUserIds] ?? <String>[],
      'mentionedUserNames': data[MessageField.mentionedUserNames] ?? <String>[],
      'reactions': data[MessageField.reactions] ?? <String, String>{},
      'deletedForEveryone': data[MessageField.deletedForEveryone] ?? false,
    };
  }

  static dynamic _dateValueForGeneratedJson(dynamic value) {
    if (value == null || value is String) return value;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value;
  }
}
