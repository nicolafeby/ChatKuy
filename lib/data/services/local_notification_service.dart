import 'dart:convert';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/data/repositories/local_notification_repository.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:chatkuy/ui/chat/voice_call/voice_call_argument.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class LocalNotificationService implements LocalNotificationRepository {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _acceptVoiceCallAction = 'accept_voice_call';
  static const _declineVoiceCallAction = 'decline_voice_call';

  @override
  Future<void> init() async {
    await _initPlugin(handleLaunchDetails: true);
  }

  static Future<void> showFromBackground(RemoteMessage message) async {
    await _initPlugin(handleLaunchDetails: false);
    LocalNotificationService().show(message);
  }

  static Future<void> _initPlugin({required bool handleLaunchDetails}) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    if (handleLaunchDetails) {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      final launchResponse = launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchResponse != null) {
        Future.delayed(
          const Duration(milliseconds: 800),
          () => _handleNotificationResponse(launchResponse),
        );
      }
    }

    const channel = AndroidNotificationChannel(
      'chat_notification',
      'Chat Notification',
      description: 'Notification for incoming chat messages',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @override
  void show(RemoteMessage message) {
    final isVoiceCall = message.data['type'] == 'voice_call';
    final title = message.notification?.title ??
        message.data['title'] ??
        (isVoiceCall ? 'Panggilan suara' : 'Pesan baru');
    final body = message.notification?.body ??
        message.data['body'] ??
        (isVoiceCall ? 'Panggilan suara masuk' : message.data['text'] ?? '');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_notification',
        'Chat Notification',
        importance: Importance.max,
        priority: Priority.high,
        category: isVoiceCall
            ? AndroidNotificationCategory.call
            : AndroidNotificationCategory.message,
        fullScreenIntent: isVoiceCall,
        actions: isVoiceCall
            ? const [
                AndroidNotificationAction(
                  _declineVoiceCallAction,
                  'Tolak',
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
                AndroidNotificationAction(
                  _acceptVoiceCallAction,
                  'Terima',
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
              ]
            : null,
      ),
    );

    _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
    final type = data['type'];

    if (type == 'voice_call') {
      if (response.actionId == _declineVoiceCallAction) {
        await _declineVoiceCall(data);
        return;
      }

      _openVoiceCall(
        data,
        autoAccept: response.actionId == _acceptVoiceCallAction,
      );
      return;
    }

    if (type == 'chat') {
      _openChatRoom(data);
    }
  }

  static Future<void> _declineVoiceCall(Map<String, dynamic> data) async {
    final callId = data['callId'];
    if (callId is! String || callId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection(FirebaseCollections.calls)
        .doc(callId)
        .update({
      CallField.status: CallStatus.declined,
      CallField.endedAt: FieldValue.serverTimestamp(),
    });
  }

  static void _openVoiceCall(
    Map<String, dynamic> data, {
    bool autoAccept = false,
  }) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final roomId = data['roomId'];
    final callId = data['callId'];
    final callerId = data['callerId'];
    final callerName = data['callerName'] ?? 'Panggilan suara';

    if (currentUid == null ||
        roomId is! String ||
        callId is! String ||
        callerId is! String) {
      return;
    }

    Get.toNamed(
      AppRouteName.VOICE_CALL_SCREEN,
      arguments: VoiceCallArgument(
        roomId: roomId,
        currentUid: currentUid,
        targetUid: callerId,
        targetName: callerName.toString(),
        callId: callId,
        isCaller: false,
        autoAccept: autoAccept,
      ),
    );
  }

  static void _openChatRoom(Map<String, dynamic> data) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final roomId = data['roomId'];
    final senderId = data['senderId'];

    if (currentUid == null || roomId is! String || senderId is! String) {
      return;
    }

    Get.toNamed(
      AppRouteName.CHAT_ROOM_SCREEN,
      arguments: ChatRoomArgument(
        roomId: roomId,
        currentUid: currentUid,
        senderId: senderId,
      ),
    );
  }
}
