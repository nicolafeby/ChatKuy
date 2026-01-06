import 'package:json_annotation/json_annotation.dart';

part 'chat_room_model.g.dart';

@JsonSerializable()
class ChatRoomModel {
  final String id;
  final List<String> participantIds;
  final String lastMessage;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime updatedAt;

  ChatRoomModel({
    this.id = '',
    required this.participantIds,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomModelToJson(this);

  static DateTime _fromJson(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
    }
    return value.toDate();
  }

  static dynamic _toJson(DateTime date) => date.toIso8601String();
}
