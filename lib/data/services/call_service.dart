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
  }) async {
    final doc = _callsRef.doc();
    await doc.set({
      CallField.roomId: roomId,
      CallField.callerId: callerId,
      CallField.calleeId: calleeId,
      CallField.callerName: callerName,
      CallField.calleeName: calleeName,
      CallField.participants: [callerId, calleeId],
      CallField.status: CallStatus.calling,
      CallField.type: 'voice',
      CallField.createdAt: FieldValue.serverTimestamp(),
    });
    return doc;
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
    return _callsRef.doc(callId).update({
      CallField.status: CallStatus.declined,
      CallField.endedAt: FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> endCall(String callId) {
    return _callsRef.doc(callId).update({
      CallField.status: CallStatus.ended,
      CallField.endedAt: FieldValue.serverTimestamp(),
    });
  }
}
