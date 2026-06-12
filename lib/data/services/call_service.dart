import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/call_write_models.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CallService implements CallRepository {
  CallService(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _callsRef => firestore.collection(FirebaseCollections.calls);

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
    final chatRoomRef = firestore.collection(FirebaseCollections.chatRooms).doc(roomId);
    final messageRef = chatRoomRef.collection(FirestoreCollection.messages).doc(doc.id);
    final batch = firestore.batch();

    final callText = _callMessageText(CallStatus.calling, callType);

    batch.set(
      doc,
      CallCreateModel(
        roomId: roomId,
        callerId: callerId,
        calleeId: calleeId,
        callerName: callerName,
        calleeName: calleeName,
        callType: callType,
      ).toFirestoreJson(),
    );

    batch.set(
      messageRef,
      CallMessageWriteModel.create(
        senderId: callerId,
        text: callText,
        createdAtClient: DateTime.now(),
        senderName: callerName,
        callId: doc.id,
        callStatus: CallStatus.calling,
        callType: callType,
        callDurationSeconds: 0,
      ).toFirestoreJson(),
    );

    batch.update(
      chatRoomRef,
      CallRoomUpdateModel.calling(
        text: callText,
        callerId: callerId,
        calleeId: calleeId,
      ).toFirestoreJson(),
    );

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
    return _callsRef.doc(callId).update(CallUpdateModel.offer(offer).toFirestoreJson());
  }

  @override
  Future<void> setAnswer({
    required String callId,
    required Map<String, dynamic> answer,
  }) {
    return _callsRef.doc(callId).update(CallUpdateModel.answer(answer).toFirestoreJson());
  }

  @override
  Future<void> requestVideoUpgrade({
    required String callId,
    required String requestedBy,
  }) {
    return _callsRef.doc(callId).update(CallUpdateModel.videoUpgradeRequest(requestedBy).toFirestoreJson());
  }

  @override
  Future<void> respondVideoUpgrade({
    required String callId,
    required bool accepted,
  }) {
    return _callsRef.doc(callId).update(CallUpdateModel.videoUpgradeResponse(accepted).toFirestoreJson());
  }

  @override
  Future<void> setVideoOffer({
    required String callId,
    required Map<String, dynamic> offer,
  }) {
    return _callsRef.doc(callId).update(CallUpdateModel.videoOffer(offer).toFirestoreJson());
  }

  @override
  Future<void> setVideoAnswer({
    required String callId,
    required Map<String, dynamic> answer,
  }) {
    return _callsRef.doc(callId).update(CallUpdateModel.videoAnswer(answer).toFirestoreJson());
  }

  @override
  Future<void> addCandidate({
    required String callId,
    required bool isCaller,
    required Map<String, dynamic> candidate,
  }) {
    final collection = isCaller ? FirestoreCollection.callerCandidates : FirestoreCollection.calleeCandidates;

    return _callsRef.doc(callId).collection(collection).add(CallCandidateModel(candidate).toFirestoreJson());
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRemoteCandidates({
    required String callId,
    required bool isCaller,
  }) {
    final collection = isCaller ? FirestoreCollection.calleeCandidates : FirestoreCollection.callerCandidates;

    return _callsRef.doc(callId).collection(collection).orderBy('createdAt').snapshots();
  }

  @override
  Future<void> markActive(String callId) {
    return _callsRef.doc(callId).update(CallUpdateModel.active().toFirestoreJson());
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
      await callRef.update(CallUpdateModel.finished(status).toFirestoreJson());
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

    batch.update(callRef, CallUpdateModel.finished(status).toFirestoreJson());

    if (roomId != null && roomId.isNotEmpty) {
      final chatRoomRef = firestore.collection(FirebaseCollections.chatRooms).doc(roomId);
      final messageRef = chatRoomRef.collection(FirestoreCollection.messages).doc(callId);

      batch.set(
        messageRef,
        CallMessageWriteModel.finished(
          text: messageText,
          callId: callId,
          callStatus: status,
          callType: callType,
          callDurationSeconds: durationSeconds,
        ).toFirestoreJson(),
        SetOptions(merge: true),
      );

      batch.update(
        chatRoomRef,
        CallRoomUpdateModel.finished(
          text: messageText,
          callerId: data[CallField.callerId] as String,
          calleeId: data[CallField.calleeId] as String?,
        ).toFirestoreJson(),
      );
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
