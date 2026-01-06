import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
  final String id;

  final String senderId;
  final String text;

  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime createdAt;

  final bool isRead;

  MessageModel({
    this.id = '',
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  MessageModel copyWith({String? id, bool? isRead}) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId,
      text: text,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  static DateTime _fromJson(dynamic value) {
    if (value is String) return DateTime.parse(value);
    return value.toDate(); // Firestore Timestamp
  }

  static dynamic _toJson(DateTime date) => date.toIso8601String();
}
