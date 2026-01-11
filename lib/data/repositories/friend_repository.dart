import 'package:chatkuy/data/models/friend_model.dart';
import 'package:chatkuy/data/models/user_model.dart';

abstract class FriendRepository {
  /// realtime stream daftar teman
  Stream<List<FriendModel>> streamFriends();

  /// ambil sekali (non-stream)
  Future<List<FriendModel>> getFriends();
}
