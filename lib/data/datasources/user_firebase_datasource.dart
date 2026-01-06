import 'package:chatkuy/core/constants/firebase_collections.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFirebaseDatasource {
  final FirebaseFirestore firestore;

  UserFirebaseDatasource(this.firestore);

  Future<void> saveUser(UserModel user) {
    return firestore
        .collection(FirebaseCollections.users)
        .doc(user.id)
        .set(user.toJson());
  }

  Future<UserModel> getUser(String userId) async {
    final doc = await firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .get();

    return UserModel.fromJson(doc.data()!).copyWith(id: doc.id);
  }
}
