// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
  senderId: json['senderId'] as String,
  text: json['text'] as String,
  createdAt: MessageModel._fromJson(json['createdAt']),
  isRead: json['isRead'] as bool? ?? false,
);

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'senderId': instance.senderId,
      'text': instance.text,
      'createdAt': MessageModel._toJson(instance.createdAt),
      'isRead': instance.isRead,
    };
