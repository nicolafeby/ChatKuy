import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CallService implements CallRepository {
  CallService(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _callsRef =>
      firestore.collection(FirebaseCollections.calls);

  @override
  Future<DocumentReference<Map<String, dynamic>>> createCall({
    required String roomId,
    required String callerId,
    required String calleeId,
    required String callerName,
    required String calleeName,
    String callType = 'voice',
  }) async {
    final doc = _callsRef.doc();
    final chatRoomRef =
        firestore.collection(FirebaseCollections.chatRooms).doc(roomId);
    final messageRef =
        chatRoomRef.collection(FirestoreCollection.messages).doc(doc.id);
    final batch = firestore.batch();

    batch.set(doc, {
      CallField.roomId: roomId,
      CallField.callerId: callerId,
      CallField.calleeId: calleeId,
      CallField.callerName: callerName,
      CallField.calleeName: calleeName,
      CallField.participants: [callerId, calleeId],
      CallField.status: CallStatus.calling,
      CallField.type: callType,
      CallField.videoUpgradeStatus: VideoUpgradeStatus.none,
      CallField.createdAt: FieldValue.serverTimestamp(),
    });

    batch.set(messageRef, {
      MessageField.senderId: callerId,
      MessageField.text: _callMessageText(CallStatus.calling, callType),
      MessageField.createdAt: FieldValue.serverTimestamp(),
      MessageField.createdAtClient: DateTime.now(),
      MessageField.deliveredTo: <String, bool>{},
      MessageField.readBy: <String, bool>{},
      MessageField.deletedFor: <String, bool>{},
      MessageField.senderName: callerName,
      MessageField.type: MessageTypeName.call,
      MessageField.callId: doc.id,
      MessageField.callStatus: CallStatus.calling,
      MessageField.callType: callType,
      MessageField.callDurationSeconds: 0,
    });

    batch.update(chatRoomRef, {
      ChatRoomField.lastMessage: _callMessageText(CallStatus.calling, callType),
      ChatRoomField.lastMessageAt: FieldValue.serverTimestamp(),
      ChatRoomField.lastSenderId: callerId,
      '${ChatRoomField.unreadCount}.$callerId': 0,
      '${ChatRoomField.unreadCount}.$calleeId': FieldValue.increment(1),
      ChatRoomField.type: MessageTypeName.call,
      '${ChatRoomField.deletedChatListFor}.$callerId': FieldValue.delete(),
      '${ChatRoomField.deletedChatListFor}.$calleeId': FieldValue.delete(),
    });

    await batch.commit();
    return doc;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchCallHistory({
    required String uid,
  }) {
    return _callsRef
        .where(CallField.participants, arrayContains: uid)
        .orderBy(CallField.createdAt, descending: true)
        .snapshots();
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCall(String callId) {
    return _callsRef.doc(callId).snapshots();
  }

  @override
  Future<void> setOffer({
    required String callId,
    required Map<String, dynamic> offer,
  }) {
    return _callsRef.doc(callId).update({CallField.offer: offer});
  }

  @override
  Future<void> setAnswer({
    required String callId,
    required Map<String, dynamic> answer,
  }) {
    return _callsRef.doc(callId).update({
      CallField.answer: answer,
      CallField.status: CallStatus.active,
      CallField.answeredAt: FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> requestVideoUpgrade({
    required String callId,
    required String requestedBy,
  }) {
    return _callsRef.doc(callId).update({
      CallField.videoUpgradeStatus: VideoUpgradeStatus.requested,
      CallField.videoUpgradeRequestedBy: requestedBy,
      CallField.videoUpgradeRequestedAt: FieldValue.serverTimestamp(),
      CallField.videoOffer: FieldValue.delete(),
      CallField.videoAnswer: FieldValue.delete(),
    });
  }

  @override
  Future<void> respondVideoUpgrade({
    required String callId,
    required bool accepted,
  }) {
    return _callsRef.doc(callId).update({
      CallField.videoUpgradeStatus:
          accepted ? VideoUpgradeStatus.accepted : VideoUpgradeStatus.declined,
      if (accepted) CallField.videoUpgradedAt: FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setVideoOffer({
    required String callId,
    required Map<String, dynamic> offer,
  }) {
    return _callsRef.doc(callId).update({CallField.videoOffer: offer});
  }

  @override
  Future<void> setVideoAnswer({
    required String callId,
    required Map<String, dynamic> answer,
  }) {
    return _callsRef.doc(callId).update({CallField.videoAnswer: answer});
  }

  @override
  Future<void> addCandidate({
    required String callId,
    required bool isCaller,
    required Map<String, dynamic> candidate,
  }) {
    final collection = isCaller
        ? FirestoreCollection.callerCandidates
        : FirestoreCollection.calleeCandidates;

    return _callsRef.doc(callId).collection(collection).add({
      ...candidate,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRemoteCandidates({
    required String callId,
    required bool isCaller,
  }) {
    final collection = isCaller
        ? FirestoreCollection.calleeCandidates
        : FirestoreCollection.callerCandidates;

    return _callsRef
        .doc(callId)
        .collection(collection)
        .orderBy('createdAt')
        .snapshots();
  }

  @override
  Future<void> markActive(String callId) {
    return _callsRef.doc(callId).update({
      CallField.status: CallStatus.active,
      CallField.answeredAt: FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> declineCall(String callId) {
    return _finishCall(callId: callId, status: CallStatus.declined);
  }

  @override
  Future<void> endCall(String callId) {
    return _finishCall(callId: callId, status: CallStatus.ended);
  }

  Future<void> _finishCall({
    required String callId,
    required String status,
  }) async {
    final callRef = _callsRef.doc(callId);
    final callSnap = await callRef.get();
    final data = callSnap.data();
    if (data == null) {
      await callRef.update({
        CallField.status: status,
        CallField.endedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    final roomId = data[CallField.roomId] as String?;
    final callType = data[CallField.type] as String? ?? 'voice';
    final durationSeconds = _durationSeconds(data[CallField.answeredAt]);
    final messageText = _callMessageText(
      status,
      callType,
      durationSeconds: durationSeconds,
    );
    final batch = firestore.batch();

    batch.update(callRef, {
      CallField.status: status,
      CallField.endedAt: FieldValue.serverTimestamp(),
    });

    if (roomId != null && roomId.isNotEmpty) {
      final chatRoomRef =
          firestore.collection(FirebaseCollections.chatRooms).doc(roomId);
      final messageRef =
          chatRoomRef.collection(FirestoreCollection.messages).doc(callId);

      batch.set(
        messageRef,
        {
          MessageField.text: messageText,
          MessageField.callStatus: status,
          MessageField.callType: callType,
          MessageField.callDurationSeconds: durationSeconds,
        },
        SetOptions(merge: true),
      );

      batch.update(chatRoomRef, {
        ChatRoomField.lastMessage: messageText,
        ChatRoomField.lastMessageAt: FieldValue.serverTimestamp(),
        ChatRoomField.lastSenderId: data[CallField.callerId],
        ChatRoomField.type: MessageTypeName.call,
        '${ChatRoomField.deletedChatListFor}.${data[CallField.callerId]}':
            FieldValue.delete(),
        '${ChatRoomField.deletedChatListFor}.${data[CallField.calleeId]}':
            FieldValue.delete(),
      });
    }

    await batch.commit();
  }

  int _durationSeconds(dynamic answeredAt) {
    if (answeredAt is! Timestamp) return 0;
    final duration = DateTime.now().difference(answeredAt.toDate()).inSeconds;
    return duration < 0 ? 0 : duration;
  }

  String _callMessageText(
    String status,
    String callType, {
    int durationSeconds = 0,
  }) {
    final label = callType == 'video' ? 'Panggilan video' : 'Panggilan suara';
    if (status == CallStatus.declined) return '$label ditolak';
    if (status == CallStatus.missed) return '$label tak terjawab';
    if (status == CallStatus.calling || status == CallStatus.ringing) {
      return '$label berlangsung';
    }
    if (durationSeconds > 0) return '$label selesai';
    return '$label berakhir';
  }
}

abstract class MessageTypeName {
  static const call = 'call';
}
