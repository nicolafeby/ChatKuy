import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/friend_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
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

  Future<List<FriendModel>> _mapToFriendModels(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (snapshot.docs.isEmpty) return [];

    // 1. Ambil uid teman
    final friendUids = snapshot.docs.map((e) => e.data()[FriendField.uid]).whereType<String>().toSet().toList();

    // 2. Ambil user data (chunked whereIn)
    final Map<String, UserModel> usersById = {};
    const chunkSize = 10;

    for (var i = 0; i < friendUids.length; i += chunkSize) {
      final chunk = friendUids.sublist(
        i,
        (i + chunkSize > friendUids.length) ? friendUids.length : i + chunkSize,
      );

      final snap = await _userRef.where(FieldPath.documentId, whereIn: chunk).get();

      for (final doc in snap.docs) {
        usersById[doc.id] = UserModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }
    }

    // 3. Build FriendModel (preserve order)
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final uid = data[FriendField.uid] as String;
      final user = usersById[uid];

      if (user == null) {
        throw StateError('User $uid not found in users collection');
      }

      return FriendModel(
        uid: uid,
        user: user,
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
