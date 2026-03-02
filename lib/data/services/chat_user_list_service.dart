import 'dart:async';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/models/chat_user_item_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_user_list_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class ChatUserListService implements ChatUserListRepository {
  ChatUserListService(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _chatRoomsRef => firestore.collection(FirebaseCollections.chatRooms);

  CollectionReference<Map<String, dynamic>> get _usersRef => firestore.collection(FirebaseCollections.users);

  /// HIVE BOX
  final Box<ChatUserItemModel> _chatListBox = Hive.box<ChatUserItemModel>('chat_list');

  @override
  Stream<List<ChatUserItemModel>> watchChatUsers({
    required String myUid,
  }) async* {
    /// 1️⃣ Emit data lokal dulu (biar tidak kosong saat refresh)
    final localData = _chatListBox.values.toList()
      ..sort((a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(a.lastMessageAt ?? DateTime(0)));

    yield localData;

    /// 2️⃣ Listen Firebase realtime
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

      final targetUids = rooms.map((room) => room.participants.firstWhere((uid) => uid != myUid)).toSet();

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

        final item = ChatUserItemModel(
          roomId: room.id,
          user: user,
          lastMessage: room.lastMessage,
          lastMessageAt: room.lastMessageAt,
          unreadCount: room.unreadCount?[myUid] ?? 0,
          imageUrl: room.imageUrl,
          type: room.type,
        );

        items.add(item);

        /// 3️⃣ Simpan / update ke Hive pakai roomId sebagai key
        await _chatListBox.put(item.roomId, item);
      }

      /// Optional: hapus room yang sudah tidak ada
      final remoteRoomIds = items.map((e) => e.roomId).toSet();
      final localRoomIds = _chatListBox.keys.cast<String>().toSet();

      final deletedIds = localRoomIds.difference(remoteRoomIds);
      for (final id in deletedIds) {
        await _chatListBox.delete(id);
      }

      /// 4️⃣ Emit ulang dari Hive (source of truth lokal)
      final updatedLocal = _chatListBox.values.toList()
        ..sort((a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(a.lastMessageAt ?? DateTime(0)));

      yield updatedLocal;
    }
  }
}
