import 'dart:async';

import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/repositories/notification_repository.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:chatkuy/ui/chat/call/call_argument.dart';
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
      unawaited(_syncFcmToken(user.uid));
    }

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }
  }

  @override
  Future<void> clearCurrentUserToken() async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user != null) {
        await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(user.uid)
            .update({AppStrings.fcmToken: ''});
      }

      await messaging.deleteToken();
    } catch (error, stackTrace) {
      await AppErrorLogger.recordError(
        error,
        stackTrace,
        reason: 'Failed to clear FCM token on logout',
        context: {'uid': user?.uid},
        showBottomSheet: false,
      );
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

    if (data['type'] == 'voice_call' || data['type'] == 'video_call') {
      final roomId = data['roomId'];
      final callId = data['callId'];
      final callerId = data['callerId'];
      final isVideoCall =
          data['type'] == 'video_call' || data['callType'] == 'video';
      final callerName = data['callerName'] ??
          (isVideoCall ? 'Panggilan video' : 'Panggilan suara');

      if (roomId == null || callId == null || callerId == null) return;

      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.key.currentState != null) {
          Get.toNamed(
            AppRouteName.CALL_SCREEN,
            arguments: CallArgument(
              roomId: roomId,
              currentUid: id,
              targetUid: callerId,
              targetName: callerName,
              callId: callId,
              isCaller: false,
              isVideoCall: isVideoCall,
            ),
          );
        }
      });
    }
  }

  Future<void> _syncFcmToken(String uid) async {
    try {
      final token = await messaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(uid)
          .update({AppStrings.fcmToken: token});
    } catch (error, stackTrace) {
      await AppErrorLogger.recordError(
        error,
        stackTrace,
        reason: 'Failed to sync FCM token on notification init',
        context: {'uid': uid},
        showBottomSheet: false,
      );
    }
  }
}
