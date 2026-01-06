import 'package:chatkuy/data/datasources/user_firebase_datasource.dart';
import 'package:chatkuy/data/models/user_model.dart';

class UserRepository {
  final UserFirebaseDatasource datasource;

  UserRepository(this.datasource);

  Future<UserModel> getUser(String userId) {
    return datasource.getUser(userId);
  }

  Future<void> saveUser(UserModel user) {
    return datasource.saveUser(user);
  }
}
