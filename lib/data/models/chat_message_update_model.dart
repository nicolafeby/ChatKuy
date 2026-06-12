import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message_update_model.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class ChatMessageUpdateModel {
  final String uid;
  final String? emoji;
  final String? text;

  @JsonKey(includeToJson: false)
  final ChatMessageUpdateType type;

  const ChatMessageUpdateModel._({
    required this.uid,
    required this.type,
    this.emoji,
    this.text,
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

  const ChatMessageUpdateModel.edit({
    required String text,
  }) : this._(
          uid: '',
          text: text,
          type: ChatMessageUpdateType.edit,
        );

  const ChatMessageUpdateModel.deleteForEveryone()
      : this._(
          uid: '',
          type: ChatMessageUpdateType.deleteForEveryone,
        );

  Map<String, dynamic> toJson() => _$ChatMessageUpdateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return switch (type) {
      ChatMessageUpdateType.delivered => {
          'deliveredTo.$uid': true,
        },
      ChatMessageUpdateType.read => {
          'readBy.$uid': true,
        },
      ChatMessageUpdateType.deletedFor => {
          'deletedFor.$uid': true,
        },
      ChatMessageUpdateType.reaction => {
          'reactions.$uid':
              emoji == null || emoji!.isEmpty ? FieldValue.delete() : emoji,
        },
      ChatMessageUpdateType.edit => {
          'text': text,
          'editedAt': FieldValue.serverTimestamp(),
        },
      ChatMessageUpdateType.deleteForEveryone => {
          'text': FieldValue.delete(),
          'imageUrl': FieldValue.delete(),
          'localImagePath': FieldValue.delete(),
          'videoUrl': FieldValue.delete(),
          'localVideoPath': FieldValue.delete(),
          'fileUrl': FieldValue.delete(),
          'localFilePath': FieldValue.delete(),
          'fileName': FieldValue.delete(),
          'fileSize': FieldValue.delete(),
          'fileExtension': FieldValue.delete(),
          'contactName': FieldValue.delete(),
          'contactPhone': FieldValue.delete(),
          'audioUrl': FieldValue.delete(),
          'localAudioPath': FieldValue.delete(),
          'audioDurationSeconds': FieldValue.delete(),
          'reactions': <String, String>{},
          'deletedForEveryone': true,
          'deletedForEveryoneAt': FieldValue.serverTimestamp(),
        },
    };
  }
}

enum ChatMessageUpdateType {
  delivered,
  read,
  deletedFor,
  reaction,
  edit,
  deleteForEveryone,
}
