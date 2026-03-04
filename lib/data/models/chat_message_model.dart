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
  @JsonKey(ignore: true)
  final MessageStatus status;

  @HiveField(12)
  final String? localImagePath;

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
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  ChatMessageModel copyWith({
    MessageStatus? status,
    String? localImagePath,
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
      imageUrl: imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
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
