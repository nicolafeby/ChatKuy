import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_room_model.g.dart';

@HiveType(typeId: 3)
@JsonSerializable(explicitToJson: true)
class ChatRoomModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final List<String> participants;
  @HiveField(2)
  final String? lastMessage;
  @HiveField(3)
  final String? lastSenderId;
  @HiveField(4)
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  @HiveField(5)
  final DateTime? lastMessageAt;
  @HiveField(6)
  final Map<String, int>? unreadCount;
  @HiveField(7)
  final String? imageUrl;
  @HiveField(8)
  final MessageType? type;

  ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageAt,
    this.unreadCount,
    this.imageUrl,
    this.type,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) => _$ChatRoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomModelToJson(this);

  /// Firestore Timestamp → DateTime
  static DateTime? _fromTimestamp(dynamic value) {
    if (value == null) return null;
    return value.toDate();
  }

  /// DateTime → Firestore Timestamp
  static dynamic _toTimestamp(DateTime? date) {
    return date;
  }
}
