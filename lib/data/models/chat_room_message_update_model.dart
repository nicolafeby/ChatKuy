import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_room_message_update_model.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class ChatRoomMessageUpdateModel {
  final String lastMessage;

  final String lastSenderId;

  final String? imageUrl;
  final String type;
  final List<String>? participants;

  @JsonKey(includeToJson: false)
  final List<String> recipientUids;

  const ChatRoomMessageUpdateModel({
    required this.lastMessage,
    required String senderId,
    required this.type,
    required this.recipientUids,
    this.imageUrl,
    this.participants,
  }) : lastSenderId = senderId;

  Map<String, dynamic> toJson() => _$ChatRoomMessageUpdateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...toJson(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount.$lastSenderId': 0,
      'deletedChatListFor.$lastSenderId': FieldValue.delete(),
      'archivedFor.$lastSenderId': FieldValue.delete(),
      for (final uid in recipientUids)
        'unreadCount.$uid': FieldValue.increment(1),
      for (final uid in recipientUids)
        'deletedChatListFor.$uid': FieldValue.delete(),
    };
  }
}
