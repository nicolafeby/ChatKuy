import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/data/services/firestore_model_converters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class UserService implements UserRepository {
  UserService(this.firestore);

  final FirebaseFirestore firestore;

  Box<UserModel> get _userBox => Hive.box<UserModel>('user_model');

  CollectionReference<UserModel> get _usersRef =>
      FirestoreModelConverters.usersRef(firestore);

  @override
  Future<UserModel> getUser(String userId) async {
    final doc = await _usersRef.doc(userId).get();

    final user = doc.data();
    if (user == null) {
      throw StateError('User $userId not found');
    }
    await _userBox.put(user.id, user);
    return user;
  }

  @override
  Future<void> updateUser(UserModel user) {
    return _usersRef.doc(user.id).update(user.toJson());
  }

  // 🔥 INI YANG KITA BUTUHKAN UNTUK CHAT ROOM
  @override
  Stream<UserModel> watchUser(String userId) {
    return _usersRef
        .doc(userId)
        .snapshots()
        .where((doc) => doc.exists)
        .asyncMap((doc) async {
      final user = doc.data();
      if (user == null) {
        throw StateError('User $userId has no data');
      }
      await _userBox.put(user.id, user);
      return user;
    });
  }
}
