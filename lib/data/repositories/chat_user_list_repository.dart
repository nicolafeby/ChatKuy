import 'package:chatkuy/data/models/chat_user_item_model.dart';

abstract class ChatUserListRepository {
  Stream<List<ChatUserItemModel>> watchChatUsers({
    required String myUid,
  });

  Future<void> deleteChat({
    required String roomId,
    required String uid,
  });

  Future<void> archiveChat({
    required String roomId,
    required String uid,
  });

  Future<void> unarchiveChat({
    required String roomId,
    required String uid,
  });

  Future<void> muteChatUntil({
    required String roomId,
    required String uid,
    required DateTime mutedUntil,
  });

  Future<void> unmuteChat({
    required String roomId,
    required String uid,
  });
}
