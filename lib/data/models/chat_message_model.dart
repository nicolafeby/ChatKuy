import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 1)
enum MessageStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  sent,

  @HiveField(2)
  failed,
}

@HiveType(typeId: 2)
enum MessageType {
  @HiveField(0)
  text,

  @HiveField(1)
  image,

  @HiveField(2)
  video,

  @HiveField(3)
  call,

  @HiveField(4)
  file,

  @HiveField(5)
  contact,

  @HiveField(6)
  audio,
}

@HiveType(typeId: 0)
@JsonSerializable()
class ChatMessageModel {
  @HiveField(0)
  final String id;

  @HiveField(11)
  final String roomId;

  @HiveField(1)
  final String senderId;

  @HiveField(2)
  final String? text;

  @HiveField(3)
  final MessageType type;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime createdAt;

  @HiveField(6)
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime createdAtClient;

  @HiveField(7)
  final String? clientMessageId;

  @HiveField(8)
  final Map<String, bool> deliveredTo;

  @HiveField(9)
  final Map<String, bool> readBy;

  @HiveField(10)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final MessageStatus status;

  @HiveField(12)
  final String? localImagePath;

  @HiveField(13)
  final String? videoUrl;

  @HiveField(14)
  final String? localVideoPath;

  @HiveField(15)
  final String? replyToMessageId;

  @HiveField(16)
  final String? replyToSenderId;

  @HiveField(17)
  final String? replyToSenderName;

  @HiveField(18)
  final String? replyToText;

  @HiveField(19)
  final MessageType? replyToType;

  @HiveField(20)
  @JsonKey(defaultValue: <String, bool>{})
  final Map<String, bool> deletedFor;

  @HiveField(21)
  final String? callId;

  @HiveField(22)
  final String? callStatus;

  @HiveField(23)
  final String? callType;

  @HiveField(24)
  final int? callDurationSeconds;

  @HiveField(25)
  final String? fileUrl;

  @HiveField(26)
  final String? localFilePath;

  @HiveField(27)
  final String? fileName;

  @HiveField(28)
  final int? fileSize;

  @HiveField(29)
  final String? fileExtension;

  @HiveField(30)
  final String? contactName;

  @HiveField(31)
  final String? contactPhone;

  @HiveField(32)
  final String? audioUrl;

  @HiveField(33)
  final String? localAudioPath;

  @HiveField(34)
  final int? audioDurationSeconds;
  @HiveField(35, defaultValue: <String>[])
  final List<String> mentionedUserIds;
  @HiveField(36, defaultValue: <String>[])
  final List<String> mentionedUserNames;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.text,
    required this.createdAt,
    required this.createdAtClient,
    this.clientMessageId,
    required this.deliveredTo,
    required this.readBy,
    this.status = MessageStatus.sent,
    required this.type,
    this.imageUrl,
    this.localImagePath,
    this.videoUrl,
    this.localVideoPath,
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyToSenderName,
    this.replyToText,
    this.replyToType,
    this.deletedFor = const {},
    this.callId,
    this.callStatus,
    this.callType,
    this.callDurationSeconds,
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
    this.mentionedUserIds = const [],
    this.mentionedUserNames = const [],
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  ChatMessageModel copyWith({
    MessageStatus? status,
    String? localImagePath,
    String? imageUrl,
    String? localVideoPath,
    String? videoUrl,
    String? localFilePath,
    String? fileUrl,
    String? localAudioPath,
    String? audioUrl,
    Map<String, bool>? deletedFor,
    String? callStatus,
    int? callDurationSeconds,
    int? audioDurationSeconds,
    List<String>? mentionedUserIds,
    List<String>? mentionedUserNames,
  }) {
    return ChatMessageModel(
      id: id,
      roomId: roomId,
      senderId: senderId,
      text: text,
      createdAt: createdAt,
      createdAtClient: createdAtClient,
      clientMessageId: clientMessageId,
      status: status ?? this.status,
      deliveredTo: deliveredTo,
      readBy: readBy,
      type: type,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      videoUrl: videoUrl ?? this.videoUrl,
      localVideoPath: localVideoPath ?? this.localVideoPath,
      fileUrl: fileUrl ?? this.fileUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      fileName: fileName,
      fileSize: fileSize,
      fileExtension: fileExtension,
      contactName: contactName,
      contactPhone: contactPhone,
      audioUrl: audioUrl ?? this.audioUrl,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      mentionedUserNames: mentionedUserNames ?? this.mentionedUserNames,
      replyToMessageId: replyToMessageId,
      replyToSenderId: replyToSenderId,
      replyToSenderName: replyToSenderName,
      replyToText: replyToText,
      replyToType: replyToType,
      deletedFor: deletedFor ?? this.deletedFor,
      callId: callId,
      callStatus: callStatus ?? this.callStatus,
      callType: callType,
      callDurationSeconds: callDurationSeconds ?? this.callDurationSeconds,
    );
  }

  static DateTime _fromTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return value.toDate();
  }

  static dynamic _toTimestamp(DateTime date) {
    return date;
  }
}
