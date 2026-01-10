import 'package:json_annotation/json_annotation.dart';

part 'chat_room_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatRoomModel {
  final String id;
  final List<String> participants;

  final String? lastMessage;
  final String? lastSenderId;

  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime? lastMessageAt;

  final Map<String, int>? unreadCount;

  ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageAt,
    this.unreadCount,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomModelFromJson(json);

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
