import 'dart:io';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/models/chat_user_item_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/hive_encryption_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

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

  @override
  Future<void> clearSensitiveData() async {
    await Future.wait([
      _clearHiveBoxes(),
      _clearChatImages(),
    ]);
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

  Future<void> _clearHiveBoxes() async {
    await Future.wait([
      _clearBox<ChatMessageModel>('chat_messages'),
      _clearBox<ChatRoomModel>('chat_room'),
      _clearBox<ChatUserItemModel>('chat_list'),
      _clearBox<UserModel>('user_model'),
    ]);
  }

  Future<void> _clearBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) return;

    await Hive.box<T>(name).clear();
  }

  Future<void> _clearChatImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final chatDir =
        Directory('${directory.path}/${StorageCollection.chatImages}');

    if (await chatDir.exists()) {
      await chatDir.delete(recursive: true);
    }
  }
}
