import 'package:cloud_firestore/cloud_firestore.dart';

abstract class CallRepository {
  Future<DocumentReference<Map<String, dynamic>>> createCall({
    required String roomId,
    required String callerId,
    required String calleeId,
    required String callerName,
    required String calleeName,
    String callType = 'voice',
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCallHistory({
    required String uid,
  });

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCall(String callId);

  Future<void> setOffer({
    required String callId,
    required Map<String, dynamic> offer,
  });

  Future<void> setAnswer({
    required String callId,
    required Map<String, dynamic> answer,
  });

  Future<void> requestVideoUpgrade({
    required String callId,
    required String requestedBy,
  });

  Future<void> respondVideoUpgrade({
    required String callId,
    required bool accepted,
  });

  Future<void> setVideoOffer({
    required String callId,
    required Map<String, dynamic> offer,
  });

  Future<void> setVideoAnswer({
    required String callId,
    required Map<String, dynamic> answer,
  });

  Future<void> addCandidate({
    required String callId,
    required bool isCaller,
    required Map<String, dynamic> candidate,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRemoteCandidates({
    required String callId,
    required bool isCaller,
  });

  Future<void> markActive(String callId);
  Future<void> declineCall(String callId);
  Future<void> endCall(String callId);
}
