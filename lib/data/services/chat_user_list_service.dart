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
        emitLocal();
      });

      messageSubscription = _messageBox.watch().listen((event) async {
        final message = event.value;
        if (message is! ChatMessageModel) return;
        await _syncLocalChatListItemFromLatestMessage(
          roomId: message.roomId,
          myUid: myUid,
        );
      });

      roomsSubscription = _chatRoomsRef
          .where(ChatRoomField.participants, arrayContains: myUid)
          .orderBy(ChatRoomField.lastMessageAt, descending: true)
          .snapshots()
          .listen((snapshot) async {
        final rooms = snapshot.docs
            .map((doc) => ChatRoomModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList();

        final localItemsByRoomId = {
          for (final item in _chatListBox.values) item.roomId: item,
        };
        final targetUids = rooms
            .map((room) => room.participants.firstWhere((uid) => uid != myUid))
            .toSet();
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
          final targetUid = room.participants.firstWhere((uid) => uid != myUid);

          final user =
              _userCache[targetUid] ?? localItemsByRoomId[room.id]?.user;
          if (user == null) continue;
          final latestLocalMessage = _latestLocalMessageForRoom(
            roomId: room.id,
            myUid: myUid,
          );
          final localMatchesRoomLatest = latestLocalMessage != null &&
              latestLocalMessage.senderId == room.lastSenderId &&
              latestLocalMessage.type == room.type &&
              _resolveLastMessage(latestLocalMessage) == room.lastMessage;
          final useLocalLatest = latestLocalMessage != null &&
              (room.lastMessageAt == null ||
                  latestLocalMessage.status == MessageStatus.pending ||
                  localMatchesRoomLatest ||
                  latestLocalMessage.createdAtClient
                      .isAfter(room.lastMessageAt!));

          final item = ChatUserItemModel(
            roomId: room.id,
            user: user,
            lastMessage: useLocalLatest
                ? _resolveLastMessage(latestLocalMessage)
                : room.lastMessage,
            lastMessageAt: useLocalLatest
                ? latestLocalMessage.createdAtClient
                : room.lastMessageAt,
            unreadCount: room.unreadCount?[myUid] ?? 0,
            imageUrl:
                useLocalLatest ? latestLocalMessage.imageUrl : room.imageUrl,
            type: useLocalLatest ? latestLocalMessage.type : room.type,
            lastSenderId: useLocalLatest
                ? latestLocalMessage.senderId
                : room.lastSenderId,
            lastMessageStatus:
                useLocalLatest ? latestLocalMessage.status : null,
            lastMessageDeliveredTo:
                useLocalLatest ? latestLocalMessage.deliveredTo : const {},
            lastMessageReadBy:
                useLocalLatest ? latestLocalMessage.readBy : const {},
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
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      await roomsSubscription?.cancel();
      await localSubscription?.cancel();
      await messageSubscription?.cancel();
    };

    return controller.stream;
  }

  ChatMessageModel? _latestLocalMessageForRoom({
    required String roomId,
    required String myUid,
  }) {
    final messages = _messageBox.values
        .where(
          (message) =>
              message.roomId == roomId && message.deletedFor[myUid] != true,
        )
        .toList()
      ..sort((a, b) => b.createdAtClient.compareTo(a.createdAtClient));

    return messages.isEmpty ? null : messages.first;
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

  Future<void> _syncLocalChatListItemFromLatestMessage({
    required String roomId,
    required String myUid,
  }) async {
    final existing = _chatListBox.get(roomId);
    if (existing == null) return;

    final latestMessage = _latestLocalMessageForRoom(
      roomId: roomId,
      myUid: myUid,
    );
    if (latestMessage == null) return;

    final existingDate = existing.lastMessageAt ?? DateTime(0);
    if (latestMessage.status != MessageStatus.pending &&
        latestMessage.createdAtClient.isBefore(existingDate)) {
      return;
    }

    await _chatListBox.put(
      roomId,
      ChatUserItemModel(
        roomId: existing.roomId,
        user: existing.user,
        lastMessage: _resolveLastMessage(latestMessage),
        lastMessageAt: latestMessage.createdAtClient,
        unreadCount: existing.unreadCount,
        imageUrl: latestMessage.imageUrl ?? existing.imageUrl,
        type: latestMessage.type,
        lastSenderId: latestMessage.senderId,
        lastMessageStatus: latestMessage.status,
        lastMessageDeliveredTo: latestMessage.deliveredTo,
        lastMessageReadBy: latestMessage.readBy,
      ),
    );
  }
}
