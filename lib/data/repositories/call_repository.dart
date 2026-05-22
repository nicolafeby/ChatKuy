import 'package:cloud_firestore/cloud_firestore.dart';

abstract class CallRepository {
  Future<DocumentReference<Map<String, dynamic>>> createCall({
    required String roomId,
    required String callerId,
    required String calleeId,
    required String callerName,
    required String calleeName,
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
