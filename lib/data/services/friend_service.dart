import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/friend_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/friend_repository.dart';
import 'package:chatkuy/data/services/firestore_model_converters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

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
  CollectionReference<Map<String, dynamic>> get _friendRef =>
      firestore.collection(FirestorePaths.userFriends(_uid));

  CollectionReference<UserModel> get _usersModelRef =>
      FirestoreModelConverters.publicProfilesRef(firestore);

  Box<UserModel> get _userBox => Hive.box<UserModel>('user_model');

  // ==============================
  // STREAM FRIEND LIST (REALTIME)
  // ==============================
  @override
  Stream<List<FriendModel>> streamFriends() {
    return _friendRef
        .orderBy(FriendField.createdAt, descending: true)
        .snapshots()
        .asyncMap(_mapToFriendModels);
  }

  Future<List<FriendModel>> _mapToFriendModels(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (snapshot.docs.isEmpty) return [];

    // 1. Ambil uid teman
    final friendUids = snapshot.docs
        .map((e) => e.data()[FriendField.uid])
        .whereType<String>()
        .toSet()
        .toList();

    // 2. Ambil profil satu per satu. Rules sengaja melarang list/query profil
    // publik untuk mencegah bulk scraping.
    final Map<String, UserModel> usersById = {};
    final snapshots = await Future.wait(
      friendUids.map((uid) => _usersModelRef.doc(uid).get()),
    );
    for (final doc in snapshots) {
      final user = doc.data();
      if (user != null) usersById[doc.id] = user;
    }

    if (usersById.isNotEmpty) {
      await _userBox.putAll(usersById);
    }

    // 3. Build FriendModel (preserve order)
    return snapshot.docs
        .map<FriendModel?>((doc) {
          final data = doc.data();
          final uid = data[FriendField.uid];
          if (uid is! String || uid.isEmpty) return null;

          final user = usersById[uid];
          if (user == null) return null;

          return FriendModel(
            uid: uid,
            user: user,
            createdAt: _dateFromTimestamp(data[FriendField.createdAt]),
          );
        })
        .whereType<FriendModel>()
        .toList();
  }

  DateTime _dateFromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  // ==============================
  // GET FRIENDS (NON-STREAM)
  // ==============================
  @override
  Future<List<FriendModel>> getFriends() async {
    final snapshot =
        await _friendRef.orderBy(FriendField.createdAt, descending: true).get();

    return _mapToFriendModels(snapshot);
  }
}
