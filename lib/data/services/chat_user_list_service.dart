import 'dart:async';

import 'package:chatkuy/core/constants/firestore.dart';
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
  final Box<ChatMessageModel> _messageBox =
      Hive.box<ChatMessageModel>('chat_messages');
  final Map<String, UserModel> _userCache = {};

  @override
  Stream<List<ChatUserItemModel>> watchChatUsers({
    required String myUid,
  }) {
    final controller = StreamController<List<ChatUserItemModel>>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? roomsSubscription;
    StreamSubscription<BoxEvent>? localSubscription;
    StreamSubscription<BoxEvent>? messageSubscription;
    final userSubscriptions =
        <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    var isApplyingRemoteRooms = false;

    List<ChatUserItemModel> localItems() {
      final localData = _chatListBox.values.toList()
        ..sort((a, b) => (b.lastMessageAt ?? DateTime(0))
            .compareTo(a.lastMessageAt ?? DateTime(0)));

      for (final item in localData) {
        if (item.user.id.isNotEmpty) {
          _userCache[item.user.id] = item.user;
        }
      }

      return localData;
    }

    void emitLocal() {
      if (!controller.isClosed) {
        controller.add(localItems());
      }
    }

    controller.onListen = () {
      emitLocal();

      localSubscription = _chatListBox.watch().listen((_) {
        if (isApplyingRemoteRooms) return;
        emitLocal();
      });

      messageSubscription = _messageBox.watch().listen((event) async {
        final message = event.value;
        if (message is! ChatMessageModel) return;
        await _syncLocalChatListItemFromMessage(
          message: message,
          myUid: myUid,
        );
      });

      roomsSubscription = _chatRoomsRef
          .where(ChatRoomField.participants, arrayContains: myUid)
          .orderBy(ChatRoomField.lastMessageAt, descending: true)
          .snapshots()
          .listen((snapshot) async {
        isApplyingRemoteRooms = true;
        try {
          final rooms = snapshot.docs
              .where((doc) {
                _latestRoomData[doc.id] = doc.data();
                return !_isChatListDeletedForUser(doc.id, myUid);
              })
              .map((doc) => ChatRoomModel.fromJson({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList();

          final localItemsByRoomId = {
            for (final item in _chatListBox.values) item.roomId: item,
          };
          final targetUids = rooms
              .map(
                  (room) => room.participants.firstWhere((uid) => uid != myUid))
              .toSet();
          _syncUserSubscriptions(
            targetUids: targetUids,
            userSubscriptions: userSubscriptions,
          );
          final missingTargetUids =
              targetUids.where((uid) => !_userCache.containsKey(uid)).toList();

          final userSnaps = await Future.wait(
            missingTargetUids.map((uid) => _usersRef.doc(uid).get()),
          );
          for (final snap in userSnaps) {
            if (!snap.exists) continue;
            _userCache[snap.id] = UserModel.fromJson({
              'id': snap.id,
              ...snap.data()!,
            });
          }

          final items = <ChatUserItemModel>[];

          for (final room in rooms) {
            final targetUid =
                room.participants.firstWhere((uid) => uid != myUid);

            final user =
                _userCache[targetUid] ?? localItemsByRoomId[room.id]?.user;
            if (user == null) continue;
            final localItem = localItemsByRoomId[room.id];
            final useLocalLatest = localItem?.lastMessageAt != null &&
                (localItem!.lastMessageStatus == MessageStatus.pending ||
                    room.lastMessageAt == null ||
                    localItem.lastMessageAt!.isAfter(room.lastMessageAt!));

            final item = ChatUserItemModel(
              roomId: room.id,
              user: user,
              lastMessage:
                  useLocalLatest ? localItem.lastMessage : room.lastMessage,
              lastMessageAt:
                  useLocalLatest ? localItem.lastMessageAt : room.lastMessageAt,
              unreadCount: room.unreadCount?[myUid] ?? 0,
              imageUrl: useLocalLatest ? localItem.imageUrl : room.imageUrl,
              type: useLocalLatest ? localItem.type : room.type,
              lastSenderId:
                  useLocalLatest ? localItem.lastSenderId : room.lastSenderId,
              lastMessageStatus:
                  useLocalLatest ? localItem.lastMessageStatus : null,
              lastMessageDeliveredTo:
                  useLocalLatest ? localItem.lastMessageDeliveredTo : const {},
              lastMessageReadBy:
                  useLocalLatest ? localItem.lastMessageReadBy : const {},
              isArchived: _isChatArchivedForUser(room.id, myUid),
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

          emitLocal();
        } finally {
          isApplyingRemoteRooms = false;
        }
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      await roomsSubscription?.cancel();
      await localSubscription?.cancel();
      await messageSubscription?.cancel();
      await Future.wait(
        userSubscriptions.values.map((subscription) => subscription.cancel()),
      );
      userSubscriptions.clear();
    };

    return controller.stream;
  }

  @override
  Future<void> deleteChat({
    required String roomId,
    required String uid,
  }) async {
    final messages = _messageBox.values
        .where((message) => message.roomId == roomId)
        .toList(growable: false);

    for (final message in messages) {
      await _messageBox.put(
        message.id,
        message.copyWith(
          deletedFor: {
            ...message.deletedFor,
            uid: true,
          },
        ),
      );
    }

    await _chatListBox.delete(roomId);

    final roomRef = _chatRoomsRef.doc(roomId);
    final updates = <Object, Object?>{
      '${ChatRoomField.deletedChatListFor}.$uid': true,
      '${ChatRoomField.unreadCount}.$uid': 0,
    };

    for (final message in messages) {
      updates['${ChatRoomField.deletedMessagesFor}.$uid.${message.id}'] = true;
    }

    await _commitRoomUpdatesInChunks(roomRef, updates);
  }

  @override
  Future<void> archiveChat({
    required String roomId,
    required String uid,
  }) async {
    final existing = _chatListBox.get(roomId);
    if (existing != null) {
      await _chatListBox.put(
        roomId,
        existing.copyWith(isArchived: true),
      );
    }

    await _chatRoomsRef.doc(roomId).update({
      '${ChatRoomField.archivedFor}.$uid': true,
    });
  }

  @override
  Future<void> unarchiveChat({
    required String roomId,
    required String uid,
  }) async {
    final existing = _chatListBox.get(roomId);
    if (existing != null) {
      await _chatListBox.put(
        roomId,
        existing.copyWith(isArchived: false),
      );
    }

    await _chatRoomsRef.doc(roomId).update({
      '${ChatRoomField.archivedFor}.$uid': FieldValue.delete(),
    });
  }

  bool _isChatListDeletedForUser(String roomId, String uid) {
    final data = _latestRoomData[roomId];
    if (data == null) return false;

    final deletedChatListFor = Map<String, dynamic>.from(
      data[ChatRoomField.deletedChatListFor] ?? {},
    );
    return deletedChatListFor[uid] == true;
  }

  bool _isChatArchivedForUser(String roomId, String uid) {
    final data = _latestRoomData[roomId];
    if (data == null) return false;

    final archivedFor = Map<String, dynamic>.from(
      data[ChatRoomField.archivedFor] ?? {},
    );
    return archivedFor[uid] == true;
  }

  final Map<String, Map<String, dynamic>> _latestRoomData = {};

  Future<void> _commitRoomUpdatesInChunks(
    DocumentReference<Map<String, dynamic>> roomRef,
    Map<Object, Object?> updates,
  ) async {
    const maxFieldsPerUpdate = 450;
    final entries = updates.entries.toList();

    for (var i = 0; i < entries.length; i += maxFieldsPerUpdate) {
      final chunkEntries = entries.skip(i).take(maxFieldsPerUpdate);
      await roomRef.update(Map<Object, Object?>.fromEntries(chunkEntries));
    }
  }

  String? _resolveLastMessage(ChatMessageModel message) {
    final text = message.text?.trim();
    if (text != null && text.isNotEmpty) return text;
    if (message.type == MessageType.image) return 'Foto';
    if (message.type == MessageType.video) return 'Video';
    if (message.type == MessageType.call) return 'Panggilan';
    if (message.type == MessageType.file) return 'Dokumen';
    if (message.type == MessageType.contact) return 'Kontak';
    return null;
  }

  Future<void> _syncLocalChatListItemFromMessage({
    required ChatMessageModel message,
    required String myUid,
  }) async {
    if (message.deletedFor[myUid] == true) return;

    final existing = _chatListBox.get(message.roomId);
    if (existing == null) return;

    final existingDate = existing.lastMessageAt ?? DateTime(0);
    if (message.status != MessageStatus.pending &&
        message.createdAtClient.isBefore(existingDate)) {
      return;
    }

    await _chatListBox.put(
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
      ),
    );
  }

  void _syncUserSubscriptions({
    required Set<String> targetUids,
    required Map<String,
            StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
        userSubscriptions,
  }) {
    final staleUids = userSubscriptions.keys
        .where((uid) => !targetUids.contains(uid))
        .toList();
    for (final uid in staleUids) {
      userSubscriptions.remove(uid)?.cancel();
    }

    for (final uid in targetUids) {
      if (userSubscriptions.containsKey(uid)) continue;

      userSubscriptions[uid] = _usersRef.doc(uid).snapshots().listen(
        (snapshot) async {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) return;

          final user = UserModel.fromJson({
            'id': snapshot.id,
            ...data,
          });
          _userCache[user.id] = user;

          await _updateLocalChatListUser(user);
        },
      );
    }
  }

  Future<void> _updateLocalChatListUser(UserModel user) async {
    final affectedItems =
        _chatListBox.values.where((item) => item.user.id == user.id).toList();

    for (final item in affectedItems) {
      await _chatListBox.put(
        item.roomId,
        ChatUserItemModel(
          roomId: item.roomId,
          user: user,
          lastMessage: item.lastMessage,
          lastMessageAt: item.lastMessageAt,
          unreadCount: item.unreadCount,
          imageUrl: item.imageUrl,
          type: item.type,
          lastSenderId: item.lastSenderId,
          lastMessageStatus: item.lastMessageStatus,
          lastMessageDeliveredTo: item.lastMessageDeliveredTo,
          lastMessageReadBy: item.lastMessageReadBy,
          isArchived: item.isArchived,
        ),
      );
    }
  }
}
