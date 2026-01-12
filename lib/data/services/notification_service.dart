import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/notification_repository.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class NotificationService implements NotificationRepository {
  NotificationService({required this.messaging});

  final FirebaseMessaging messaging;

  @override
  Future<void> init() async {
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': token});
      }
    }

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

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
      final senderId = data['senderId'];

      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.key.currentState != null) {
          Get.toNamed(
            AppRouteName.CHAT_ROOM_SCREEN,
            arguments: ChatRoomArgument(
              roomId: roomId,
              currentUid: id,
              senderId: senderId,
            ),
          );
        }
      });
    }
  }
}
