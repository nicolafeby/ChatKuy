/// ==============================
/// ROOT COLLECTIONS
/// ==============================
abstract class FirebaseCollections {
  static const users = 'users';
  static const chatRooms = 'chat_rooms';
  static const calls = 'calls';
}

/// ==============================
/// SUB COLLECTIONS
/// ==============================
abstract class FirestoreCollection {
  static const messages = 'messages';
  static const friends = 'friends';
  static const friendRequests = 'friend_requests';
  static const outgoingFriendRequests = 'outgoing_friend_requests';
  static const callerCandidates = 'caller_candidates';
  static const calleeCandidates = 'callee_candidates';
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
  static const admins = 'admins';
  static const createdBy = 'createdBy';
  static const name = 'name';
  static const photoUrl = 'photoUrl';
  static const isGroup = 'isGroup';
  static const lastMessage = 'lastMessage';
  static const lastMessageAt = 'lastMessageAt';
  static const lastSenderId = 'lastSenderId';
  static const unreadCount = 'unreadCount';
  static const imageUrl = 'imageUrl';
  static const type = 'type';
  static const deletedMessagesFor = 'deletedMessagesFor';
  static const deletedChatListFor = 'deletedChatListFor';
  static const archivedFor = 'archivedFor';
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
  static const senderName = 'senderName';
  static const imageUrl = 'imageUrl';
  static const localImagePath = 'localImagePath';
  static const videoUrl = 'videoUrl';
  static const localVideoPath = 'localVideoPath';
  static const type = 'type';
  static const replyToMessageId = 'replyToMessageId';
  static const replyToSenderId = 'replyToSenderId';
  static const replyToSenderName = 'replyToSenderName';
  static const replyToText = 'replyToText';
  static const replyToType = 'replyToType';
  static const deletedFor = 'deletedFor';
  static const callId = 'callId';
  static const callStatus = 'callStatus';
  static const callType = 'callType';
  static const callDurationSeconds = 'callDurationSeconds';
  static const fileUrl = 'fileUrl';
  static const localFilePath = 'localFilePath';
  static const fileName = 'fileName';
  static const fileSize = 'fileSize';
  static const fileExtension = 'fileExtension';
  static const contactName = 'contactName';
  static const contactPhone = 'contactPhone';
  static const audioUrl = 'audioUrl';
  static const localAudioPath = 'localAudioPath';
  static const audioDurationSeconds = 'audioDurationSeconds';
  static const mentionedUserIds = 'mentionedUserIds';
  static const mentionedUserNames = 'mentionedUserNames';
  static const reactions = 'reactions';
}

/// ==============================
/// CALL FIELDS
/// ==============================
abstract class CallField {
  static const roomId = 'roomId';
  static const callerId = 'callerId';
  static const calleeId = 'calleeId';
  static const callerName = 'callerName';
  static const calleeName = 'calleeName';
  static const participants = 'participants';
  static const status = 'status';
  static const type = 'type';
  static const offer = 'offer';
  static const answer = 'answer';
  static const videoUpgradeStatus = 'videoUpgradeStatus';
  static const videoUpgradeRequestedBy = 'videoUpgradeRequestedBy';
  static const videoUpgradeRequestedAt = 'videoUpgradeRequestedAt';
  static const videoOffer = 'videoOffer';
  static const videoAnswer = 'videoAnswer';
  static const videoUpgradedAt = 'videoUpgradedAt';
  static const createdAt = 'createdAt';
  static const answeredAt = 'answeredAt';
  static const endedAt = 'endedAt';
}

abstract class CallStatus {
  static const calling = 'calling';
  static const ringing = 'ringing';
  static const active = 'active';
  static const declined = 'declined';
  static const ended = 'ended';
  static const missed = 'missed';
}

abstract class VideoUpgradeStatus {
  static const none = 'none';
  static const requested = 'requested';
  static const accepted = 'accepted';
  static const declined = 'declined';
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

abstract class StorageCollection {
  static const chatImages = 'chat_images';
  static const chatVideos = 'chat_videos';
  static const chatFiles = 'chat_files';
  static const chatAudios = 'chat_audios';
}
