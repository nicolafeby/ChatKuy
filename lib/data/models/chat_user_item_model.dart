import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:chatkuy/data/models/user_model.dart';

part 'chat_user_item_model.g.dart';

@HiveType(typeId: 4)
@JsonSerializable(explicitToJson: true)
class ChatUserItemModel {
  @HiveField(0)
  final String roomId;
  @HiveField(1)
  final UserModel user;
  @HiveField(2)
  final String? lastMessage;
  @HiveField(3)
  final DateTime? lastMessageAt;
  @HiveField(4)
  final int unreadCount;
  @HiveField(5)
  final String? imageUrl;
  @HiveField(6)
  final MessageType? type;

  ChatUserItemModel({
    required this.roomId,
    required this.user,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    this.imageUrl,
    this.type,
  });

  factory ChatUserItemModel.fromJson(Map<String, dynamic> json) =>
      _$ChatUserItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatUserItemModelToJson(this);
}
