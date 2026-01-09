import 'package:chatkuy/data/models/user_model.dart';

extension UserModelFields on UserModel {
  static const id = 'id';
  static const name = 'name';
  static const email = 'email';
  static const username = 'username';
  static const photoUrl = 'photoUrl';
  static const isEmailVerified = 'isEmailVerified';
  static const isOnline = 'isOnline';
  static const lastOnlineAt = 'lastOnlineAt';
}
