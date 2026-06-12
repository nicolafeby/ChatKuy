import 'package:chatkuy/core/constants/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_room_update_model.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class ChatRoomUpdateModel {
  final String? name;
  final String? photoUrl;

  @JsonKey(includeToJson: false)
  final List<String>? invitedMemberUids;

  @JsonKey(includeToJson: false)
  final String? promotedAdminUid;

  @JsonKey(includeToJson: false)
  final String? removedMemberUid;

  @JsonKey(includeToJson: false)
  final String? typingUid;

  @JsonKey(includeToJson: false)
  final bool? isTyping;

  @JsonKey(includeToJson: false)
  final String? deletedMessageUid;

  @JsonKey(includeToJson: false)
  final String? deletedMessageId;

  @JsonKey(includeToJson: false)
  final String? resetUnreadUid;

  const ChatRoomUpdateModel({
    this.name,
    this.photoUrl,
    this.invitedMemberUids,
    this.promotedAdminUid,
    this.removedMemberUid,
    this.typingUid,
    this.isTyping,
    this.deletedMessageUid,
    this.deletedMessageId,
    this.resetUnreadUid,
  });

  const ChatRoomUpdateModel.inviteMembers(List<String> memberUids)
      : this(invitedMemberUids: memberUids);

  const ChatRoomUpdateModel.promoteAdmin(String memberUid)
      : this(promotedAdminUid: memberUid);

  const ChatRoomUpdateModel.removeMember(String memberUid)
      : this(removedMemberUid: memberUid);

  const ChatRoomUpdateModel.groupInfo({
    String? name,
    String? photoUrl,
  }) : this(
          name: name,
          photoUrl: photoUrl,
        );

  const ChatRoomUpdateModel.typing({
    required String uid,
    required bool isTyping,
  }) : this(
          typingUid: uid,
          isTyping: isTyping,
        );

  const ChatRoomUpdateModel.deletedMessageFor({
    required String uid,
    required String messageId,
  }) : this(
          deletedMessageUid: uid,
          deletedMessageId: messageId,
        );

  const ChatRoomUpdateModel.resetUnread(String uid) : this(resetUnreadUid: uid);

  Map<String, dynamic> toJson() => _$ChatRoomUpdateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    final invitedMemberUids = this.invitedMemberUids;
    final promotedAdminUid = this.promotedAdminUid;
    final removedMemberUid = this.removedMemberUid;
    final typingUid = this.typingUid;
    final deletedMessageUid = this.deletedMessageUid;
    final deletedMessageId = this.deletedMessageId;
    final resetUnreadUid = this.resetUnreadUid;

    return {
      ...toJson(),
      if (invitedMemberUids != null) ...{
        ChatRoomField.participants: FieldValue.arrayUnion(invitedMemberUids),
        for (final uid in invitedMemberUids)
          '${ChatRoomField.unreadCount}.$uid': 0,
        for (final uid in invitedMemberUids)
          '${ChatRoomField.deletedChatListFor}.$uid': FieldValue.delete(),
      },
      if (promotedAdminUid != null)
        ChatRoomField.admins: FieldValue.arrayUnion([promotedAdminUid]),
      if (removedMemberUid != null) ...{
        ChatRoomField.participants: FieldValue.arrayRemove([removedMemberUid]),
        ChatRoomField.admins: FieldValue.arrayRemove([removedMemberUid]),
        '${ChatRoomField.unreadCount}.$removedMemberUid': FieldValue.delete(),
        '${ChatRoomField.deletedChatListFor}.$removedMemberUid': true,
      },
      if (typingUid != null) 'typing.$typingUid': isTyping,
      if (deletedMessageUid != null && deletedMessageId != null)
        '${ChatRoomField.deletedMessagesFor}.$deletedMessageUid.$deletedMessageId':
            true,
      if (resetUnreadUid != null)
        '${ChatRoomField.unreadCount}.$resetUnreadUid': 0,
    };
  }
}
