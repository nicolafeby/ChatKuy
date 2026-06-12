import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_room_write_model.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class ChatRoomWriteModel {
  final List<String>? participants;
  final List<String>? admins;
  final String? createdBy;
  final String? name;
  final String? photoUrl;
  final bool? isGroup;
  final String? lastMessage;
  final String? lastSenderId;
  final Map<String, int>? unreadCount;

  @JsonKey(includeToJson: false)
  final String? archiveUid;

  @JsonKey(includeToJson: false)
  final String? unarchiveUid;

  @JsonKey(includeToJson: false)
  final bool useServerLastMessageAt;

  const ChatRoomWriteModel({
    this.participants,
    this.admins,
    this.createdBy,
    this.name,
    this.photoUrl,
    this.isGroup,
    this.lastMessage,
    this.lastSenderId,
    this.unreadCount,
    this.archiveUid,
    this.unarchiveUid,
    this.useServerLastMessageAt = false,
  });

  ChatRoomWriteModel.directRoom({
    required String currentUid,
    required String targetUid,
  }) : this(
          participants: [currentUid, targetUid],
          unreadCount: {
            currentUid: 0,
            targetUid: 0,
          },
          useServerLastMessageAt: true,
        );

  ChatRoomWriteModel.groupRoom({
    required String currentUid,
    required String name,
    required List<String> participants,
    String? photoUrl,
  }) : this(
          participants: participants,
          admins: [currentUid],
          createdBy: currentUid,
          name: name,
          photoUrl: photoUrl,
          isGroup: true,
          unreadCount: {
            for (final uid in participants) uid: 0,
          },
          useServerLastMessageAt: true,
        );

  const ChatRoomWriteModel.archiveForUser(String uid) : this(archiveUid: uid);

  const ChatRoomWriteModel.unarchiveForUser(String uid)
      : this(unarchiveUid: uid);

  Map<String, dynamic> toJson() => _$ChatRoomWriteModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...toJson(),
      if (useServerLastMessageAt) 'lastMessage': null,
      if (useServerLastMessageAt) 'lastMessageAt': FieldValue.serverTimestamp(),
      if (useServerLastMessageAt) 'lastSenderId': null,
      if (archiveUid != null) 'archivedFor.$archiveUid': true,
      if (unarchiveUid != null)
        'archivedFor.$unarchiveUid': FieldValue.delete(),
    };
  }
}
