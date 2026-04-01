import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService implements UserRepository {
  UserService(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<UserModel> getUser(String userId) async {
    final doc = await firestore.collection(FirebaseCollections.users).doc(userId).get();

    return UserModel.fromJson(doc.data()!).copyWith(id: doc.id);
  }

  @override
  Future<void> updateUser(UserModel user) {
    return firestore.collection(FirebaseCollections.users).doc(user.id).update(user.toJson());
  }

  // 🔥 INI YANG KITA BUTUHKAN UNTUK CHAT ROOM
  @override
  Stream<UserModel> watchUser(String userId) {
    return firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .snapshots()
        .where((doc) => doc.exists)
        .map((doc) {
      return UserModel.fromJson(doc.data()!).copyWith(id: doc.id);
    });
  }
}
