import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/models/chat_user_item_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/hive_encryption_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveEncryptionService implements HiveEncryptionRepository {
  HiveEncryptionService(this.secureStorage);

  final SecureStorageRepository secureStorage;

  @override
  Future<void> openEncryptedBoxes() async {
    final encryptionKey = await secureStorage.getHiveEncryptionKey();
    final cipher = HiveAesCipher(encryptionKey);

    await _openEncryptedBox<ChatMessageModel>('chat_messages', cipher);
    await _openEncryptedBox<ChatRoomModel>('chat_room', cipher);
    await _openEncryptedBox<ChatUserItemModel>('chat_list', cipher);
    await _openEncryptedBox<UserModel>('user_model', cipher);
  }

  Future<void> _openEncryptedBox<T>(String name, HiveCipher cipher) async {
    try {
      await Hive.openBox<T>(
        name,
        encryptionCipher: cipher,
      );
    } on HiveError {
      await _migratePlainTextBox<T>(name, cipher);
    }
  }

  Future<void> _migratePlainTextBox<T>(String name, HiveCipher cipher) async {
    final legacyBox = await Hive.openBox<T>(name);
    final legacyEntries = {
      for (final key in legacyBox.keys) key: legacyBox.get(key) as T,
    };

    await legacyBox.close();
    await Hive.deleteBoxFromDisk(name);

    final encryptedBox = await Hive.openBox<T>(
      name,
      encryptionCipher: cipher,
    );

    if (legacyEntries.isNotEmpty) {
      await encryptedBox.putAll(legacyEntries);
    }
  }
}
