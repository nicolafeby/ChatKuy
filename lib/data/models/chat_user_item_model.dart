import 'package:json_annotation/json_annotation.dart';
import 'package:chatkuy/data/models/user_model.dart';

part 'chat_user_item_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatUserItemModel {
  final String roomId;
  final UserModel user;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatUserItemModel({
    required this.roomId,
    required this.user,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatUserItemModel.fromJson(Map<String, dynamic> json) =>
      _$ChatUserItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatUserItemModelToJson(this);
}
