import 'package:chatkuy/data/models/request_friend_model.dart';

abstract class FriendRequestRepository {
  /// request masuk (orang lain → kita)
  Stream<List<FriendRequestModel>> streamIncomingFriendRequests();

  /// request keluar (kita → orang lain)
  Stream<List<FriendRequestModel>> streamOutgoingFriendRequests();

  Future<void> sendFriendRequestByUsername(String username);
  Future<void> acceptFriendRequest({
    required String fromUid,
    required String requestId,
  });
}
