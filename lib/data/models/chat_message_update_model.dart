import 'package:chatkuy/core/constants/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message_update_model.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class ChatMessageUpdateModel {
  final String uid;
  final String? emoji;

  @JsonKey(includeToJson: false)
  final ChatMessageUpdateType type;

  const ChatMessageUpdateModel._({
    required this.uid,
    required this.type,
    this.emoji,
  });

  const ChatMessageUpdateModel.delivered(String uid)
      : this._(
          uid: uid,
          type: ChatMessageUpdateType.delivered,
        );

  const ChatMessageUpdateModel.read(String uid)
      : this._(
          uid: uid,
          type: ChatMessageUpdateType.read,
        );

  const ChatMessageUpdateModel.deletedFor(String uid)
      : this._(
          uid: uid,
          type: ChatMessageUpdateType.deletedFor,
        );

  const ChatMessageUpdateModel.reaction({
    required String uid,
    required String? emoji,
  }) : this._(
          uid: uid,
          emoji: emoji,
          type: ChatMessageUpdateType.reaction,
        );

  Map<String, dynamic> toJson() => _$ChatMessageUpdateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return switch (type) {
      ChatMessageUpdateType.delivered => {
          '${MessageField.deliveredTo}.$uid': true,
        },
      ChatMessageUpdateType.read => {
          '${MessageField.readBy}.$uid': true,
        },
      ChatMessageUpdateType.deletedFor => {
          '${MessageField.deletedFor}.$uid': true,
        },
      ChatMessageUpdateType.reaction => {
          '${MessageField.reactions}.$uid': emoji == null || emoji!.isEmpty ? FieldValue.delete() : emoji,
        },
    };
  }
}

enum ChatMessageUpdateType {
  delivered,
  read,
  deletedFor,
  reaction,
}
