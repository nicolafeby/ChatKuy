import 'package:json_annotation/json_annotation.dart';

part 'chat_message_model.g.dart';

enum MessageStatus {
  pending,
  sent,
  failed,
}

@JsonSerializable()
class ChatMessageModel {
  final String id;
  final String senderId;
  final String text;

  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime createdAt;

  /// 🔥 penting untuk reconcile local vs server
  final String? clientMessageId;

  /// UI only
  @JsonKey(ignore: true)
  final MessageStatus status;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.clientMessageId,
    this.status = MessageStatus.sent,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  ChatMessageModel copyWith({
    MessageStatus? status,
  }) {
    return ChatMessageModel(
      id: id,
      senderId: senderId,
      text: text,
      createdAt: createdAt,
      clientMessageId: clientMessageId,
      status: status ?? this.status,
    );
  }

  static DateTime _fromTimestamp(dynamic value) {
    return value.toDate();
  }

  static dynamic _toTimestamp(DateTime date) {
    return date;
  }
}
