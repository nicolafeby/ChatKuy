import 'package:chatkuy/data/models/user_model.dart';

abstract class UserRepository {
  Future<UserModel> getUser(String userId);
  Future<void> updateUser(UserModel user);
}
