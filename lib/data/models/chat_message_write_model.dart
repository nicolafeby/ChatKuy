import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message_write_model.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class ChatMessageWriteModel {
  final String senderId;
  final String? text;
  final String? imageUrl;
  final String? localImagePath;
  final String? videoUrl;
  final String? localVideoPath;
  final String? fileUrl;
  final String? localFilePath;
  final String? fileName;
  final int? fileSize;
  final String? fileExtension;
  final String? contactName;
  final String? contactPhone;
  final String? audioUrl;
  final String? localAudioPath;
  final int? audioDurationSeconds;

  @JsonKey(toJson: _dateToFirestore)
  final DateTime createdAtClient;

  final String? clientMessageId;
  final String senderName;
  final String type;
  final String? replyToMessageId;
  final String? replyToSenderId;
  final String? replyToSenderName;
  final String? replyToText;
  final String? replyToType;
  final List<String> mentionedUserIds;
  final List<String> mentionedUserNames;

  const ChatMessageWriteModel({
    required this.senderId,
    required this.createdAtClient,
    required this.senderName,
    required this.type,
    this.text,
    this.imageUrl,
    this.localImagePath,
    this.videoUrl,
    this.localVideoPath,
    this.fileUrl,
    this.localFilePath,
    this.fileName,
    this.fileSize,
    this.fileExtension,
    this.contactName,
    this.contactPhone,
    this.audioUrl,
    this.localAudioPath,
    this.audioDurationSeconds,
    this.clientMessageId,
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyToSenderName,
    this.replyToText,
    this.replyToType,
    this.mentionedUserIds = const [],
    this.mentionedUserNames = const [],
  });

  Map<String, Object?> toJson() => _$ChatMessageWriteModelToJson(this);

  Map<String, Object?> toFirestoreJson() {
    return {
      ...toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'deliveredTo': <String, bool>{},
      'readBy': <String, bool>{},
      'deletedFor': <String, bool>{},
      'reactions': <String, String>{},
    };
  }

  static DateTime _dateToFirestore(DateTime value) => value;
}
