/// ==============================
/// ROOT COLLECTIONS
/// ==============================
abstract class FirebaseCollections {
  static const users = 'users';
  static const chatRooms = 'chat_rooms';
}

/// ==============================
/// SUB COLLECTIONS
/// ==============================
abstract class FirestoreCollection {
  static const messages = 'messages';
  static const friends = 'friends';
  static const friendRequests = 'friend_requests';
  static const outgoingFriendRequests = 'outgoing_friend_requests';
}

/// ==============================
/// FIRESTORE PATH HELPERS
/// ==============================
abstract class FirestorePaths {
  FirestorePaths._();

  /// users/{uid}
  static String user(String uid) => '${FirebaseCollections.users}/$uid';

  /// users/{uid}/friends
  static String userFriends(String uid) => '${user(uid)}/${FirestoreCollection.friends}';

  /// users/{uid}/friends/{friendUid}
  static String userFriendDoc(String uid, String friendUid) => '${userFriends(uid)}/$friendUid';

  /// chat_rooms/{roomId}
  static String chatRoom(String roomId) => '${FirebaseCollections.chatRooms}/$roomId';

  /// chat_rooms/{roomId}/messages
  static String chatMessages(String roomId) => '${chatRoom(roomId)}/${FirestoreCollection.messages}';

  /// users/{uid}/friend_requests
  static String userFriendRequests(String uid) => '${user(uid)}/${FirestoreCollection.friendRequests}';

  /// users/{uid}/friend_requests/{requestId}
  static String userFriendRequestDoc(String uid, String requestId) => '${userFriendRequests(uid)}/$requestId';
}

/// ==============================
/// CHAT ROOM FIELDS
/// ==============================
abstract class ChatRoomField {
  static const participants = 'participants';
  static const lastMessage = 'lastMessage';
  static const lastMessageAt = 'lastMessageAt';
  static const lastSenderId = 'lastSenderId';
  static const unreadCount = 'unreadCount';
}

/// ==============================
/// MESSAGE FIELDS
/// ==============================
abstract class MessageField {
  static const senderId = 'senderId';
  static const text = 'text';
  static const createdAt = 'createdAt';
  static const createdAtClient = 'createdAtClient';
  static const clientMessageId = 'clientMessageId';
  static const deliveredTo = 'deliveredTo';
  static const readBy = 'readBy';
}

/// ==============================
/// FRIEND FIELDS
/// ==============================
abstract class FriendField {
  static const uid = 'uid';
  static const username = 'username';
  static const name = 'name';
  static const photoUrl = 'photoUrl';
  static const createdAt = 'createdAt';
  static const isEmailVerified = 'isEmailVerified';
}

/// ==============================
/// FRIEND REQUEST
/// ==============================
abstract class FriendRequestField {
  static const fromUid = 'fromUid';
  static const toUid = 'toUid';
  static const status = 'status';
  static const createdAt = 'createdAt';
}

abstract class FriendRequestStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const rejected = 'rejected';
}
