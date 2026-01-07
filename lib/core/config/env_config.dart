import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'dev';

  static String get projectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static String get usersCollection =>
      dotenv.env['FIRESTORE_USERS_COLLECTION'] ?? 'users';

  static String get chatRoomsCollection =>
      dotenv.env['FIRESTORE_CHAT_ROOMS_COLLECTION'] ?? 'chat_rooms';

  static String get messagesCollection =>
      dotenv.env['FIRESTORE_MESSAGES_COLLECTION'] ?? 'messages';
}
