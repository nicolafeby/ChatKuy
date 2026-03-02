import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/models/chat_user_item_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';

Future<void> hiveServiceTest() async {
  setUpAll(() async {
    await setUpTestHive();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageModelAdapter());
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MessageStatusAdapter());
    }

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MessageTypeAdapter());
    }

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ChatRoomModelAdapter());
    }

    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ChatUserItemModelAdapter());
    }

    if (Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(GenderAdapter());
    }

    if (Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(UserModelAdapter());
    }

    await Hive.openBox<ChatMessageModel>('chat_messages');
    await Hive.openBox<ChatRoomModel>('chat_room');
    await Hive.openBox<ChatUserItemModel>('chat_list');
    await Hive.openBox<UserModel>('user_mocel');
  });

  tearDownAll(() async {
    await tearDownTestHive();
  });
}
