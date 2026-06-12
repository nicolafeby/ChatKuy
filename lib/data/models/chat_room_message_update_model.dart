import 'package:chatkuy/core/constants/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_room_message_update_model.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class ChatRoomMessageUpdateModel {
  final String lastMessage;

  @JsonKey(name: ChatRoomField.lastSenderId)
  final String senderId;

  final String? imageUrl;
  final String type;
  final List<String>? participants;

  @JsonKey(includeToJson: false)
  final List<String> recipientUids;

  const ChatRoomMessageUpdateModel({
    required this.lastMessage,
    required this.senderId,
    required this.type,
    required this.recipientUids,
    this.imageUrl,
    this.participants,
  });

  Map<String, dynamic> toJson() => _$ChatRoomMessageUpdateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...toJson(),
      ChatRoomField.lastMessageAt: FieldValue.serverTimestamp(),
      '${ChatRoomField.unreadCount}.$senderId': 0,
      '${ChatRoomField.deletedChatListFor}.$senderId': FieldValue.delete(),
      '${ChatRoomField.archivedFor}.$senderId': FieldValue.delete(),
      for (final uid in recipientUids)
        '${ChatRoomField.unreadCount}.$uid': FieldValue.increment(1),
      for (final uid in recipientUids)
        '${ChatRoomField.deletedChatListFor}.$uid': FieldValue.delete(),
    };
  }
}
