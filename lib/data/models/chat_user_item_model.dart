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
  @HiveField(7)
  final String? lastSenderId;
  @HiveField(8)
  final MessageStatus? lastMessageStatus;
  @HiveField(9)
  final Map<String, bool> lastMessageDeliveredTo;
  @HiveField(10)
  final Map<String, bool> lastMessageReadBy;
  @HiveField(11, defaultValue: false)
  final bool isArchived;
  @HiveField(12, defaultValue: false)
  final bool isGroup;
  @HiveField(13)
  final String? groupName;
  @HiveField(14)
  final String? groupPhotoUrl;
  @HiveField(15, defaultValue: <String>[])
  final List<String> participants;
  @HiveField(16, defaultValue: <String>[])
  final List<String> admins;

  ChatUserItemModel({
    required this.roomId,
    required this.user,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    this.imageUrl,
    this.type,
    this.lastSenderId,
    this.lastMessageStatus,
    this.lastMessageDeliveredTo = const {},
    this.lastMessageReadBy = const {},
    this.isArchived = false,
    this.isGroup = false,
    this.groupName,
    this.groupPhotoUrl,
    this.participants = const [],
    this.admins = const [],
  });

  factory ChatUserItemModel.fromJson(Map<String, dynamic> json) => _$ChatUserItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatUserItemModelToJson(this);

  ChatUserItemModel copyWith({
    String? roomId,
    UserModel? user,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? imageUrl,
    MessageType? type,
    String? lastSenderId,
    MessageStatus? lastMessageStatus,
    Map<String, bool>? lastMessageDeliveredTo,
    Map<String, bool>? lastMessageReadBy,
    bool? isArchived,
    bool? isGroup,
    String? groupName,
    String? groupPhotoUrl,
    List<String>? participants,
    List<String>? admins,
  }) {
    return ChatUserItemModel(
      roomId: roomId ?? this.roomId,
      user: user ?? this.user,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      lastMessageDeliveredTo: lastMessageDeliveredTo ?? this.lastMessageDeliveredTo,
      lastMessageReadBy: lastMessageReadBy ?? this.lastMessageReadBy,
      isArchived: isArchived ?? this.isArchived,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupPhotoUrl: groupPhotoUrl ?? this.groupPhotoUrl,
      participants: participants ?? this.participants,
      admins: admins ?? this.admins,
    );
  }
}
