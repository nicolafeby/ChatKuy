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
  @HiveField(9, defaultValue: false)
  final bool isGroup;
  @HiveField(10)
  final String? name;
  @HiveField(11)
  final String? photoUrl;
  @HiveField(12, defaultValue: <String>[])
  final List<String> admins;
  @HiveField(13)
  final String? createdBy;
  @HiveField(14, defaultValue: <String, DateTime?>{})
  @JsonKey(
    fromJson: _mutedUntilFromJson,
    toJson: _mutedUntilToJson,
    defaultValue: <String, DateTime?>{},
  )
  final Map<String, DateTime?> mutedUntil;

  ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageAt,
    this.unreadCount,
    this.imageUrl,
    this.type,
    this.isGroup = false,
    this.name,
    this.photoUrl,
    this.admins = const [],
    this.createdBy,
    this.mutedUntil = const {},
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

  static Map<String, DateTime?> _mutedUntilFromJson(dynamic value) {
    if (value is! Map) return const {};

    return value.map((key, mutedUntil) {
      return MapEntry(key.toString(), _fromTimestamp(mutedUntil));
    });
  }

  static Map<String, dynamic> _mutedUntilToJson(
    Map<String, DateTime?> mutedUntil,
  ) {
    return mutedUntil.map((key, value) => MapEntry(key, value));
  }

  bool isMutedFor(String uid, {DateTime? now}) {
    final mutedUntilForUser = mutedUntil[uid];
    if (mutedUntilForUser == null) return false;

    return mutedUntilForUser.isAfter(now ?? DateTime.now());
  }
}
