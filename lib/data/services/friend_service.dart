import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/friend_model.dart';
import 'package:chatkuy/data/repositories/friend_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService implements FriendRepository {
  FriendService(this.auth, this.firestore);

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  // ==============================
  // AUTH
  // ==============================
  String get _uid {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // ==============================
  // COLLECTION REFS
  // ==============================
  CollectionReference<Map<String, dynamic>> get _friendRef => firestore.collection(FirestorePaths.userFriends(_uid));

  CollectionReference<Map<String, dynamic>> get _userRef => firestore.collection(FirebaseCollections.users);

  // ==============================
  // STREAM FRIEND LIST (REALTIME)
  // ==============================
  @override
  Stream<List<FriendModel>> streamFriends() {
    return _friendRef.orderBy(FriendField.createdAt, descending: true).snapshots().asyncMap(_mapToFriendModels);
  }

  // ==============================
  // JOIN FRIENDS -> USERS
  // ==============================
  Future<List<FriendModel>> _mapToFriendModels(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    // Ambil uid teman
    final friendUids = snapshot.docs.map((e) => e.data()[FriendField.uid]).whereType<String>().toList();

    if (friendUids.isEmpty) {
      return [];
    }

    // Firestore whereIn max 10 → chunk
    final List<Map<String, dynamic>> userDocs = [];
    const chunkSize = 10;

    for (var i = 0; i < friendUids.length; i += chunkSize) {
      final chunk = friendUids.sublist(
        i,
        (i + chunkSize > friendUids.length) ? friendUids.length : i + chunkSize,
      );

      final snap = await _userRef.where(FieldPath.documentId, whereIn: chunk).get();

      userDocs.addAll(snap.docs.map((d) => {
            'id': d.id,
            ...d.data(),
          }));
    }

    final usersById = {
      for (final u in userDocs) u['id'] as String: u,
    };

    // Build FriendModel sesuai urutan friends.createdAt
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final uid = data[FriendField.uid] as String;
      final user = usersById[uid];

      return FriendModel(
        uid: uid,
        username: user?[FriendField.username] as String? ?? '',
        displayName: user?[FriendField.name] as String?,
        photoUrl: user?[FriendField.photoUrl] as String?,
        createdAt: (data[FriendField.createdAt] as Timestamp).toDate(),
      );
    }).toList();
  }

  // ==============================
  // GET FRIENDS (NON-STREAM)
  // ⚠️ TIDAK JOIN USERS
  // ==============================
  @override
  Future<List<FriendModel>> getFriends() async {
    final snapshot = await _friendRef.orderBy(FriendField.createdAt, descending: true).get();

    return snapshot.docs.map((doc) => FriendModel.fromJson(doc.data())).toList();
  }
}
