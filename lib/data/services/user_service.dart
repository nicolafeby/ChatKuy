import 'package:chatkuy/core/config/env_config.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService implements UserRepository {
  UserService(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<UserModel> getUser(String userId) async {
    final doc = await firestore
        .collection(EnvConfig.usersCollection)
        .doc(userId)
        .get();

    return UserModel.fromJson(doc.data()!).copyWith(id: doc.id);
  }

  @override
  Future<void> updateUser(UserModel user) {
    return firestore
        .collection(EnvConfig.usersCollection)
        .doc(user.id)
        .update(user.toJson());
  }
}
