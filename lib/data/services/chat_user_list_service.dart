import 'dart:async';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/models/chat_user_item_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_user_list_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUserListService implements ChatUserListRepository {
  ChatUserListService(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _chatRoomsRef => firestore.collection(FirebaseCollections.chatRooms);

  CollectionReference<Map<String, dynamic>> get _usersRef => firestore.collection(FirebaseCollections.users);

  @override
  Stream<List<ChatUserItemModel>> watchChatUsers({
    required String myUid,
  }) async* {
    await for (final snapshot in _chatRoomsRef
        .where(ChatRoomField.participants, arrayContains: myUid)
        .orderBy(ChatRoomField.lastMessageAt, descending: true)
        .snapshots()) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoomModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      final targetUids = rooms
          .map(
            (room) => room.participants.firstWhere((uid) => uid != myUid),
          )
          .toSet(); // hindari duplicate

      final userSnaps = await Future.wait(
        targetUids.map((uid) => _usersRef.doc(uid).get()),
      );

      final usersMap = <String, UserModel>{};
      for (final snap in userSnaps) {
        if (!snap.exists) continue;
        usersMap[snap.id] = UserModel.fromJson({
          'id': snap.id,
          ...snap.data()!,
        });
      }

      final items = <ChatUserItemModel>[];

      for (final room in rooms) {
        final targetUid = room.participants.firstWhere((uid) => uid != myUid);

        final user = usersMap[targetUid];
        if (user == null) continue;

        items.add(
          ChatUserItemModel(
            roomId: room.id,
            user: user,
            lastMessage: room.lastMessage,
            lastMessageAt: room.lastMessageAt,
            unreadCount: room.unreadCount?[myUid] ?? 0,
          ),
        );
      }

      yield items;
    }
  }
}
