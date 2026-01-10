abstract class FirebaseCollections {
  static const users = 'users';
  static const chatRooms = 'chat_rooms';
  static const messages = 'messages';
}

class FirestoreCollection {
  static const chatRooms = 'chat_rooms';
  static const messages = 'messages';
}

class ChatRoomField {
  static const participants = 'participants';
  static const lastMessage = 'lastMessage';
  static const lastMessageAt = 'lastMessageAt';
  static const lastSenderId = 'lastSenderId';
  static const unreadCount = 'unreadCount';
}

class MessageField {
  static const senderId = 'senderId';
  static const text = 'text';
  static const createdAt = 'createdAt';
}
