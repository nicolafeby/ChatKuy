import 'dart:async';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/models/chat_user_item_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_user_list_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class ChatUserListService implements ChatUserListRepository {
  ChatUserListService(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _chatRoomsRef =>
      firestore.collection(FirebaseCollections.chatRooms);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      firestore.collection(FirebaseCollections.users);

  /// HIVE BOX
  final Box<ChatUserItemModel> _chatListBox =
      Hive.box<ChatUserItemModel>('chat_list');

  @override
  Stream<List<ChatUserItemModel>> watchChatUsers({
    required String myUid,
  }) async* {
    /// 1️⃣ Emit data lokal dulu (biar tidak kosong saat refresh)
    final localData = _chatListBox.values.toList()
      ..sort((a, b) => (b.lastMessageAt ?? DateTime(0))
          .compareTo(a.lastMessageAt ?? DateTime(0)));

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
      final roomDataById = {
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };

      final latestVisibleByRoom = <String, _LatestVisibleMessage?>{};
      final latestVisibleResults = await Future.wait(
        rooms.map(
          (room) => _syncRecentMessagesAndResolveLatestVisible(
            roomId: room.id,
            myUid: myUid,
            roomDeletedMessageIds: _roomDeletedMessageIdsForUser(
              roomDataById[room.id],
              myUid,
            ),
          ),
        ),
      );

      for (var index = 0; index < rooms.length; index++) {
        latestVisibleByRoom[rooms[index].id] = latestVisibleResults[index];
      }

      final targetUids = rooms
          .map((room) => room.participants.firstWhere((uid) => uid != myUid))
          .toSet();

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
        final latestVisible = latestVisibleByRoom[room.id];

        final item = ChatUserItemModel(
          roomId: room.id,
          user: user,
          lastMessage: latestVisible?.text,
          lastMessageAt: latestVisible?.createdAt,
          unreadCount: room.unreadCount?[myUid] ?? 0,
          imageUrl: latestVisible?.imageUrl,
          type: latestVisible?.type,
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
        ..sort((a, b) => (b.lastMessageAt ?? DateTime(0))
            .compareTo(a.lastMessageAt ?? DateTime(0)));

      yield updatedLocal;
    }
  }

  Future<_LatestVisibleMessage?> _syncRecentMessagesAndResolveLatestVisible({
    required String roomId,
    required String myUid,
    required Set<String> roomDeletedMessageIds,
  }) async {
    try {
      final messagesSnap = await _chatRoomsRef
          .doc(roomId)
          .collection(FirestoreCollection.messages)
          .orderBy(MessageField.createdAtClient, descending: true)
          .limit(30)
          .get();

      final batch = firestore.batch();
      var hasUpdates = false;
      _LatestVisibleMessage? latestVisibleMessage;

      for (final doc in messagesSnap.docs) {
        final data = doc.data();
        final senderId = data[MessageField.senderId];
        final deliveredTo =
            Map<String, dynamic>.from(data[MessageField.deliveredTo] ?? {});
        final deletedFor =
            Map<String, dynamic>.from(data[MessageField.deletedFor] ?? {});
        final isDeletedForMe =
            deletedFor[myUid] == true || roomDeletedMessageIds.contains(doc.id);

        final messageType = _messageTypeFromString(data[MessageField.type]);
        latestVisibleMessage ??= isDeletedForMe
            ? null
            : _LatestVisibleMessage(
                text: _resolveLastMessage(data[MessageField.text], messageType),
                imageUrl: data[MessageField.imageUrl],
                createdAt: _dateFromFirestore(data[MessageField.createdAt]) ??
                    _dateFromFirestore(data[MessageField.createdAtClient]),
                type: messageType,
              );

        if (senderId == myUid || deliveredTo[myUid] == true || isDeletedForMe) {
          continue;
        }

        batch.update(doc.reference, {
          '${MessageField.deliveredTo}.$myUid': true,
        });
        hasUpdates = true;
      }

      if (hasUpdates) {
        await batch.commit();
      }

      return latestVisibleMessage;
    } catch (error, stackTrace) {
      await AppErrorLogger.recordError(
        error,
        stackTrace,
        reason: 'Mark chat list messages delivered failed',
        context: {
          'room_id': roomId,
          'current_uid': myUid,
        },
        showBottomSheet: false,
      );
      return null;
    }
  }

  MessageType _messageTypeFromString(dynamic value) {
    if (value == MessageType.image.name) return MessageType.image;
    if (value == MessageType.video.name) return MessageType.video;
    if (value == MessageType.call.name) return MessageType.call;
    return MessageType.text;
  }

  String? _resolveLastMessage(dynamic text, MessageType type) {
    if (text is String && text.trim().isNotEmpty) return text.trim();
    if (type == MessageType.image) return 'Foto';
    if (type == MessageType.video) return 'Video';
    if (type == MessageType.call) return 'Panggilan';
    return null;
  }

  Set<String> _roomDeletedMessageIdsForUser(
    Map<String, dynamic>? roomData,
    String myUid,
  ) {
    final deletedMessagesFor = Map<String, dynamic>.from(
      roomData?[ChatRoomField.deletedMessagesFor] ?? {},
    );
    final deletedMessagesById = Map<String, dynamic>.from(
      deletedMessagesFor[myUid] ?? {},
    );

    return deletedMessagesById.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toSet();
  }

  DateTime? _dateFromFirestore(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }
}

class _LatestVisibleMessage {
  const _LatestVisibleMessage({
    required this.text,
    required this.imageUrl,
    required this.createdAt,
    required this.type,
  });

  final String? text;
  final String? imageUrl;
  final DateTime? createdAt;
  final MessageType type;
}
