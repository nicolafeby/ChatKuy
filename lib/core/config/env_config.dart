import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String _fromDotenv(
    String key,
    String defaultValue,
  ) {
    try {
      return dotenv.env[key] ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  static String get appEnv {
    const value = String.fromEnvironment('APP_ENV');
    if (value.isNotEmpty) return value;
    return _fromDotenv('APP_ENV', 'dev');
  }

  static String get projectId {
    const value = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if (value.isNotEmpty) return value;
    return _fromDotenv('FIREBASE_PROJECT_ID', '');
  }

  static String get usersCollection {
    const value = String.fromEnvironment('FIRESTORE_USERS_COLLECTION');
    if (value.isNotEmpty) return value;
    return _fromDotenv('FIRESTORE_USERS_COLLECTION', 'users');
  }

  static String get chatRoomsCollection {
    const value = String.fromEnvironment('FIRESTORE_CHAT_ROOMS_COLLECTION');
    if (value.isNotEmpty) return value;
    return _fromDotenv(
      'FIRESTORE_CHAT_ROOMS_COLLECTION',
      'chat_rooms',
    );
  }

  static String get messagesCollection {
    const value = String.fromEnvironment('FIRESTORE_MESSAGES_COLLECTION');
    if (value.isNotEmpty) return value;
    return _fromDotenv(
      'FIRESTORE_MESSAGES_COLLECTION',
      'messages',
    );
  }
}
