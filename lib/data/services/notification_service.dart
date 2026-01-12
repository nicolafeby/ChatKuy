import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/data/repositories/notification_repository.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class NotificationService implements NotificationRepository {
  NotificationService({required this.messaging});

  final FirebaseMessaging messaging;

  @override
  Future<void> init() async {
    await messaging.requestPermission();

    // Background → user klik notif
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    // Terminated → app dibuka dari notif
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }
  }

  @override
  void handleMessage(RemoteMessage message) {
    final id = FirebaseAuth.instance.currentUser?.uid;
    final data = message.data;

    if (id == null) return;

    if (data['type'] == 'chat') {
      final roomId = data['roomId'];

      Get.toNamed(
        AppRouteName.CHAT_ROOM_SCREEN,
        arguments: ChatRoomArgument(
          roomId: roomId,
          currentUid: id,
        ),
      );
    }
  }
}
