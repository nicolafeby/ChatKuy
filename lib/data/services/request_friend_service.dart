import 'package:chatkuy/data/models/request_friend_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/repositories/friend_request_repository.dart';

class FriendRequestService implements FriendRequestRepository {
  FriendRequestService(this.auth, this.firestore);

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  String get _uid {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('User belum login');
    }
    return user.uid;
  }

  /// ======================================================
  /// STREAM INCOMING FRIEND REQUEST (PENDING)
  /// ======================================================
  @override
  Stream<List<FriendRequestModel>> streamIncomingFriendRequests() {
    return firestore
        .doc(FirestorePaths.user(_uid))
        .collection(FirestoreCollection.friendRequests)
        .where(
          FriendRequestField.status,
          isEqualTo: FriendRequestStatus.pending,
        )
        .orderBy(
          FriendRequestField.createdAt,
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(FriendRequestModel.fromFirestore).toList(),
        );
  }

  /// ======================================================
  /// STREAM OUTGOING FRIEND REQUEST (PENDING)
  /// ======================================================
  @override
  Stream<List<FriendRequestModel>> streamOutgoingFriendRequests() {
    return firestore
        .doc(FirestorePaths.user(_uid))
        .collection(FirestoreCollection.outgoingFriendRequests)
        .where(
          FriendRequestField.status,
          isEqualTo: FriendRequestStatus.pending,
        )
        .orderBy(
          FriendRequestField.createdAt,
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(FriendRequestModel.fromFirestore).toList(),
        );
  }

  // ==============================
  // SEND FRIEND REQUEST
  // ==============================
  @override
  Future<void> sendFriendRequestByUsername(String username) async {
    // ============================
    // CARI USER BERDASARKAN USERNAME
    // ============================
    final query = await firestore
        .collection(FirebaseCollections.users)
        .where(FriendField.username, isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Username tidak ditemukan');
    }

    final targetSnap = query.docs.first;
    final targetUid = targetSnap.id;

    // ============================
    // VALIDASI DASAR
    // ============================
    if (targetUid == _uid) {
      throw Exception('Tidak bisa menambahkan diri sendiri');
    }

    if (targetSnap.data()[FriendField.isEmailVerified] != true) {
      throw Exception('User belum memverifikasi email');
    }

    // ============================
    // CEK SUDAH BERTEMAN
    // ============================
    final friendSnap = await firestore.collection(FirestorePaths.userFriends(_uid)).doc(targetUid).get();

    if (friendSnap.exists) {
      throw Exception('Anda sudah berteman');
    }

    // ============================
    // CEK REQUEST PENDING (DARI SAYA KE DIA)
    // ============================
    final existingRequest = await firestore
        .collection(FirestorePaths.userFriendRequests(targetUid))
        .where(FriendRequestField.fromUid, isEqualTo: _uid)
        .where(
          FriendRequestField.status,
          isEqualTo: FriendRequestStatus.pending,
        )
        .limit(1)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('Permintaan pertemanan sudah dikirim');
    }

    // ============================
    // SNAPSHOT USER SAYA
    // ============================
    final mySnap = await firestore.doc(FirestorePaths.user(_uid)).get();

    // ============================
    // MODEL INCOMING (TARGET)
    // -> tampilkan data PENGIRIM
    // ============================
    final incomingRequest = FriendRequestModel(
      id: '',
      fromUid: _uid,
      toUid: targetUid,
      username: mySnap[FriendField.username],
      displayName: mySnap[FriendField.name],
      photoUrl: mySnap.data()?[FriendField.photoUrl],
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    // ============================
    // MODEL OUTGOING (SAYA)
    // -> tampilkan data TARGET
    // ============================
    final outgoingRequest = FriendRequestModel(
      id: '',
      fromUid: _uid,
      toUid: targetUid,
      username: targetSnap[FriendField.username],
      displayName: targetSnap[FriendField.name],
      photoUrl: targetSnap.data()[FriendField.photoUrl],
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    // ============================
    // DUAL WRITE (ATOMIC)
    // ============================
    final batch = firestore.batch();

    final incomingRef = firestore.collection(FirestorePaths.userFriendRequests(targetUid)).doc();

    final outgoingRef = firestore
        .doc(FirestorePaths.user(_uid))
        .collection(FirestoreCollection.outgoingFriendRequests)
        .doc(incomingRef.id);

    batch.set(incomingRef, incomingRequest.toCreateJson());
    batch.set(outgoingRef, outgoingRequest.toCreateJson());

    await batch.commit();
  }

  @override
  Future<void> cancelFriendRequest({required String targetUid}) async {
    // ============================
    // CARI REQUEST PENDING
    // ============================
    final incomingQuery = await firestore
        .collection(FirestorePaths.userFriendRequests(targetUid))
        .where(FriendRequestField.fromUid, isEqualTo: _uid)
        .where(
          FriendRequestField.status,
          isEqualTo: FriendRequestStatus.pending,
        )
        .limit(1)
        .get();

    if (incomingQuery.docs.isEmpty) {
      throw Exception('Permintaan pertemanan tidak ditemukan');
    }

    final incomingDoc = incomingQuery.docs.first;
    final requestId = incomingDoc.id;

    // ============================
    // DUAL DELETE (ATOMIC)
    // ============================
    final batch = firestore.batch();

    final incomingRef = firestore.collection(FirestorePaths.userFriendRequests(targetUid)).doc(requestId);

    final outgoingRef =
        firestore.doc(FirestorePaths.user(_uid)).collection(FirestoreCollection.outgoingFriendRequests).doc(requestId);

    batch.delete(incomingRef);
    batch.delete(outgoingRef);

    await batch.commit();
  }

  // ==============================
  // ACCEPT FRIEND REQUEST
  // ==============================
  @override
  Future<void> acceptFriendRequest({
    required String fromUid,
    required String requestId,
  }) async {
    final myUid = _uid;

    final batch = firestore.batch();

    // ============================
    // 1️⃣ HAPUS INCOMING REQUEST
    // ============================
    final incomingRef =
        firestore.doc(FirestorePaths.user(myUid)).collection(FirestoreCollection.friendRequests).doc(requestId);

    batch.delete(incomingRef);

    // ============================
    // 2️⃣ HAPUS OUTGOING REQUEST (PENGIRIM)
    // ============================
    final outgoingRef = firestore
        .doc(FirestorePaths.user(fromUid))
        .collection(FirestoreCollection.outgoingFriendRequests)
        .doc(requestId);

    batch.delete(outgoingRef);

    // ============================
    // 3️⃣ ADD FRIEND (ME → THEM)
    // ============================
    batch.set(
      firestore.doc(
        FirestorePaths.userFriendDoc(myUid, fromUid),
      ),
      {
        FriendField.uid: fromUid,
        FriendField.createdAt: FieldValue.serverTimestamp(),
      },
    );

    // ============================
    // 4️⃣ ADD FRIEND (THEM → ME)
    // ============================
    batch.set(
      firestore.doc(
        FirestorePaths.userFriendDoc(fromUid, myUid),
      ),
      {
        FriendField.uid: myUid,
        FriendField.createdAt: FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  @override
  Future<void> rejectFriendRequest({
    required String senderUid,
  }) async {
    // ============================
    // CARI REQUEST PENDING (INCOMING)
    // ============================
    final incomingQuery = await firestore
        .collection(FirestorePaths.userFriendRequests(_uid))
        .where(FriendRequestField.fromUid, isEqualTo: senderUid)
        .where(
          FriendRequestField.status,
          isEqualTo: FriendRequestStatus.pending,
        )
        .limit(1)
        .get();

    if (incomingQuery.docs.isEmpty) {
      throw Exception('Permintaan pertemanan tidak ditemukan');
    }

    final incomingDoc = incomingQuery.docs.first;
    final requestId = incomingDoc.id;

    // ============================
    // DUAL DELETE (ATOMIC)
    // ============================
    final batch = firestore.batch();

    // Hapus incoming request (punya saya)
    final incomingRef = firestore.collection(FirestorePaths.userFriendRequests(_uid)).doc(requestId);

    // Hapus outgoing request (punya pengirim)
    final outgoingRef = firestore
        .doc(FirestorePaths.user(senderUid))
        .collection(FirestoreCollection.outgoingFriendRequests)
        .doc(requestId);

    batch.delete(incomingRef);
    batch.delete(outgoingRef);

    await batch.commit();
  }
}
