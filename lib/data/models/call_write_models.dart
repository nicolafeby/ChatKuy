import 'package:chatkuy/core/constants/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'call_write_models.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class CallCreateModel {
  final String roomId;
  final String callerId;
  final String calleeId;
  final String callerName;
  final String calleeName;

  @JsonKey(name: CallField.type)
  final String callType;

  const CallCreateModel({
    required this.roomId,
    required this.callerId,
    required this.calleeId,
    required this.callerName,
    required this.calleeName,
    required this.callType,
  });

  Map<String, dynamic> toJson() => _$CallCreateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...toJson(),
      CallField.participants: [callerId, calleeId],
      CallField.status: CallStatus.calling,
      CallField.videoUpgradeStatus: VideoUpgradeStatus.none,
      CallField.createdAt: FieldValue.serverTimestamp(),
    };
  }
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class CallUpdateModel {
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;
  final String? status;
  final String? videoUpgradeStatus;
  final String? videoUpgradeRequestedBy;
  final Map<String, dynamic>? videoOffer;
  final Map<String, dynamic>? videoAnswer;

  @JsonKey(includeToJson: false)
  final bool useAnsweredAtServerTimestamp;

  @JsonKey(includeToJson: false)
  final bool useEndedAtServerTimestamp;

  @JsonKey(includeToJson: false)
  final bool useVideoUpgradeRequestedAtServerTimestamp;

  @JsonKey(includeToJson: false)
  final bool useVideoUpgradedAtServerTimestamp;

  @JsonKey(includeToJson: false)
  final bool clearVideoOffer;

  @JsonKey(includeToJson: false)
  final bool clearVideoAnswer;

  const CallUpdateModel({
    this.offer,
    this.answer,
    this.status,
    this.videoUpgradeStatus,
    this.videoUpgradeRequestedBy,
    this.videoOffer,
    this.videoAnswer,
    this.useAnsweredAtServerTimestamp = false,
    this.useEndedAtServerTimestamp = false,
    this.useVideoUpgradeRequestedAtServerTimestamp = false,
    this.useVideoUpgradedAtServerTimestamp = false,
    this.clearVideoOffer = false,
    this.clearVideoAnswer = false,
  });

  const CallUpdateModel.offer(Map<String, dynamic> offer) : this(offer: offer);

  const CallUpdateModel.answer(Map<String, dynamic> answer)
      : this(
          answer: answer,
          status: CallStatus.active,
          useAnsweredAtServerTimestamp: true,
        );

  const CallUpdateModel.videoUpgradeRequest(String requestedBy)
      : this(
          videoUpgradeStatus: VideoUpgradeStatus.requested,
          videoUpgradeRequestedBy: requestedBy,
          useVideoUpgradeRequestedAtServerTimestamp: true,
          clearVideoOffer: true,
          clearVideoAnswer: true,
        );

  const CallUpdateModel.videoUpgradeResponse(bool accepted)
      : this(
          videoUpgradeStatus: accepted ? VideoUpgradeStatus.accepted : VideoUpgradeStatus.declined,
          useVideoUpgradedAtServerTimestamp: accepted,
        );

  const CallUpdateModel.videoOffer(Map<String, dynamic> offer) : this(videoOffer: offer);

  const CallUpdateModel.videoAnswer(Map<String, dynamic> answer) : this(videoAnswer: answer);

  const CallUpdateModel.active()
      : this(
          status: CallStatus.active,
          useAnsweredAtServerTimestamp: true,
        );

  const CallUpdateModel.ringing() : this(status: CallStatus.ringing);

  const CallUpdateModel.finished(String status)
      : this(
          status: status,
          useEndedAtServerTimestamp: true,
        );

  Map<String, dynamic> toJson() => _$CallUpdateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...toJson(),
      if (useAnsweredAtServerTimestamp) CallField.answeredAt: FieldValue.serverTimestamp(),
      if (useEndedAtServerTimestamp) CallField.endedAt: FieldValue.serverTimestamp(),
      if (useVideoUpgradeRequestedAtServerTimestamp) CallField.videoUpgradeRequestedAt: FieldValue.serverTimestamp(),
      if (useVideoUpgradedAtServerTimestamp) CallField.videoUpgradedAt: FieldValue.serverTimestamp(),
      if (clearVideoOffer) CallField.videoOffer: FieldValue.delete(),
      if (clearVideoAnswer) CallField.videoAnswer: FieldValue.delete(),
    };
  }
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class CallCandidateModel {
  final Map<String, dynamic> candidate;

  const CallCandidateModel(this.candidate);

  Map<String, dynamic> toJson() => _$CallCandidateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...candidate,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class CallMessageWriteModel {
  final String? senderId;
  final String text;

  @JsonKey(toJson: _dateToFirestore)
  final DateTime? createdAtClient;
  final String? senderName;
  final String callId;
  final String callStatus;
  final String callType;
  final int callDurationSeconds;

  @JsonKey(includeToJson: false)
  final bool createMessage;

  const CallMessageWriteModel.create({
    required this.senderId,
    required this.text,
    required this.createdAtClient,
    required this.senderName,
    required this.callId,
    required this.callStatus,
    required this.callType,
    required this.callDurationSeconds,
  }) : createMessage = true;

  const CallMessageWriteModel.finished({
    required this.text,
    required this.callId,
    required this.callStatus,
    required this.callType,
    required this.callDurationSeconds,
  })  : senderId = null,
        createdAtClient = null,
        senderName = null,
        createMessage = false;

  Map<String, dynamic> toJson() => _$CallMessageWriteModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...toJson(),
      if (createMessage) MessageField.createdAt: FieldValue.serverTimestamp(),
      if (createMessage) MessageField.deliveredTo: <String, bool>{},
      if (createMessage) MessageField.readBy: <String, bool>{},
      if (createMessage) MessageField.deletedFor: <String, bool>{},
      if (createMessage) MessageField.type: 'call',
    };
  }

  static DateTime? _dateToFirestore(DateTime? value) => value;
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class CallRoomUpdateModel {
  @JsonKey(name: ChatRoomField.lastMessage)
  final String text;

  @JsonKey(name: ChatRoomField.lastSenderId)
  final String callerId;

  final String? calleeId;

  @JsonKey(includeToJson: false)
  final bool incrementCalleeUnread;

  const CallRoomUpdateModel.calling({
    required this.text,
    required this.callerId,
    required this.calleeId,
  }) : incrementCalleeUnread = true;

  const CallRoomUpdateModel.finished({
    required this.text,
    required this.callerId,
    required this.calleeId,
  }) : incrementCalleeUnread = false;

  Map<String, dynamic> toJson() => _$CallRoomUpdateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...toJson()..remove('calleeId'),
      ChatRoomField.lastMessageAt: FieldValue.serverTimestamp(),
      ChatRoomField.type: 'call',
      '${ChatRoomField.unreadCount}.$callerId': 0,
      if (calleeId != null && incrementCalleeUnread) '${ChatRoomField.unreadCount}.$calleeId': FieldValue.increment(1),
      '${ChatRoomField.deletedChatListFor}.$callerId': FieldValue.delete(),
      if (calleeId != null) '${ChatRoomField.deletedChatListFor}.$calleeId': FieldValue.delete(),
    };
  }
}
