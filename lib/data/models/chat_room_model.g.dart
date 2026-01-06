// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomModel _$ChatRoomModelFromJson(Map<String, dynamic> json) =>
    ChatRoomModel(
      id: json['id'] as String? ?? '',
      participantIds:
          (json['participantIds'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      lastMessage: json['lastMessage'] as String,
      updatedAt: ChatRoomModel._fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$ChatRoomModelToJson(ChatRoomModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participantIds': instance.participantIds,
      'lastMessage': instance.lastMessage,
      'updatedAt': ChatRoomModel._toJson(instance.updatedAt),
    };
