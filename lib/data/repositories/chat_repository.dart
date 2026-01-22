import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';

abstract class ChatRepository {
  /// Chat List (Realtime)
  Stream<List<ChatRoomModel>> watchChatRooms({
    required String uid,
  });

  /// Messages in Room (Realtime)
  Stream<List<ChatMessageModel>> watchMessages({
    required String roomId,
  });

  /// Send message
  Future<void> sendMessage({
    required String roomId,
    required String text,
  });

  /// Create room if not exists
  Future<String> createOrGetRoom({
    required String currentUid,
    required String targetUid,
  });

  Stream<Map<String, bool>> watchTyping({required String roomId});
  Future<void> setTyping({
    required String roomId,
    required String uid,
    required bool isTyping,
  });
  Future<void> markDelivered({
    required String roomId,
    required String messageId,
    required String uid,
  });

  Future<void> markRead({
    required String roomId,
    required String messageId,
    required String uid,
  });

  Future<void> resetUnread({
    required String roomId,
    required String uid,
  });
}
