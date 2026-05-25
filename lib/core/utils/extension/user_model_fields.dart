import 'package:chatkuy/data/models/user_model.dart';

extension UserModelFields on UserModel {
  static const id = 'id';
  static const name = 'name';
  static const email = 'email';
  static const pendingEmail = 'pendingEmail';
  static const username = 'username';
  static const photoUrl = 'photoUrl';
  static const isEmailVerified = 'isEmailVerified';
  static const isOnline = 'isOnline';
  static const lastOnlineAt = 'lastOnlineAt';
  static const isEmailVisible = 'isEmailVisible';
  static const isBirthDateVisible = 'isBirthDateVisible';
  static const isOnlineStatusVisible = 'isOnlineStatusVisible';
}
