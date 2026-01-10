import 'package:json_annotation/json_annotation.dart';

part 'chat_message_model.g.dart';

@JsonSerializable()
class ChatMessageModel {
  final String id;
  final String senderId;
  final String text;

  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  static DateTime _fromTimestamp(dynamic value) {
    return value.toDate();
  }

  static dynamic _toTimestamp(DateTime date) {
    return date;
  }
}
