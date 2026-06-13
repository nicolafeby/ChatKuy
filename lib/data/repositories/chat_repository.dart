import 'dart:io';

import 'package:chatkuy/core/helpers/image_saver_helper.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/models/user_model.dart';

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
    String? targetUid,
    String? text,
    String? imageUrl,
    File? imageFile,
    String? videoUrl,
    File? videoFile,
    String? fileUrl,
    File? file,
    String? fileName,
    int? fileSize,
    String? fileExtension,
    String? contactName,
    String? contactPhone,
    String? audioUrl,
    File? audioFile,
    String? localAudioPath,
    int? audioDurationSeconds,
    required MessageType type,
    String? clientMessageId,
    String? localImagePath,
    String? localVideoPath,
    String? localFilePath,
    ChatMessageModel? replyToMessage,
    String? replyToSenderName,
    List<String> mentionedUserIds = const [],
    List<String> mentionedUserNames = const [],
    void Function(int progress)? onUploadProgress,
  });

  /// Create room if not exists
  Future<String> createOrGetRoom({
    required String currentUid,
    required String targetUid,
  });

  /// Deterministic 1:1 room id without creating the room document.
  String directRoomId({
    required String currentUid,
    required String targetUid,
  });

  Future<String> createGroupRoom({
    required String currentUid,
    required String name,
    required List<String> memberUids,
    String? photoUrl,
  });

  Stream<ChatRoomModel> watchRoom({required String roomId});

  Stream<List<UserModel>> watchGroupMembers({required String roomId});

  Future<void> inviteGroupMembers({
    required String roomId,
    required String adminUid,
    required List<String> memberUids,
  });

  Future<void> promoteGroupAdmin({
    required String roomId,
    required String adminUid,
    required String memberUid,
  });

  Future<void> removeGroupMember({
    required String roomId,
    required String adminUid,
    required String memberUid,
  });

  Future<void> updateGroupInfo({
    required String roomId,
    required String adminUid,
    String? name,
    String? photoUrl,
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

  Future<void> deleteMessageForMe({
    required String roomId,
    required String messageId,
    required String uid,
  });

  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String text,
    required String uid,
  });

  Future<void> deleteMessageForEveryone({
    required String roomId,
    required String messageId,
    required String uid,
  });

  Future<void> setMessageReaction({
    required String roomId,
    required String messageId,
    required String uid,
    required String? emoji,
  });

  Future<void> resetUnread({
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

  Future<LocalImageModel> uploadImage(
      {required File file, required String roomId});
}
