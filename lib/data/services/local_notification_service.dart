import 'dart:async';
import 'dart:convert';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/data/repositories/local_notification_repository.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:chatkuy/ui/chat/voice_call/voice_call_argument.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class LocalNotificationService implements LocalNotificationRepository {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _acceptVoiceCallAction = 'accept_voice_call';
  static const _declineVoiceCallAction = 'decline_voice_call';
  static const _chatChannelId = 'chat_notification';
  static const _callChannelId = 'incoming_call_notification';
  static NotificationResponse? _pendingLaunchResponse;
  static ({
    Map<String, dynamic> data,
    bool autoAccept,
    bool closeAppOnEnd,
  })? _lastIncomingCall;
  static ({
    Map<String, dynamic> data,
    bool autoAccept,
    bool closeAppOnEnd,
  })? _pendingVoiceCall;
  static bool _isCallKitListenerAttached = false;
  static final Set<String> _handledAcceptedCallIds = {};
  static final Map<String, bool> _closeAppAfterCallById = {};
  static final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _callStatusSubscriptions = {};

  @override
  Future<void> init() async {
    await _initPlugin(handleLaunchDetails: true);
    _listenCallKitEvents();
  }

  static Future<void> showFromBackground(RemoteMessage message) async {
    await _initPlugin(handleLaunchDetails: false);
    await LocalNotificationService().show(message);
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
      if (launchDetails?.didNotificationLaunchApp == true && launchResponse != null) {
        _pendingLaunchResponse = launchResponse;
      }
    }

    const channel = AndroidNotificationChannel(
      _chatChannelId,
      'Chat Notification',
      description: 'Notification for incoming chat messages',
      importance: Importance.max,
    );

    const callChannel = AndroidNotificationChannel(
      _callChannelId,
      'Incoming Call',
      description: 'Notification for incoming voice calls',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(callChannel);

    if (handleLaunchDetails) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final notificationGranted = await androidPlugin?.requestNotificationsPermission();
      final fullScreenGranted = await androidPlugin?.requestFullScreenIntentPermission();
      debugPrint(
        'LocalNotification permission: notifications=$notificationGranted fullScreen=$fullScreenGranted',
      );
      await FlutterCallkitIncoming.requestNotificationPermission({
        'rationaleMessagePermission': 'ChatKuy membutuhkan izin notifikasi untuk menampilkan panggilan masuk.',
        'postNotificationMessageRequired': 'Silakan izinkan notifikasi agar panggilan masuk bisa muncul.',
      });
      await FlutterCallkitIncoming.requestFullIntentPermission();
    }
  }

  @override
  Future<void> show(RemoteMessage message) async {
    final isVoiceCall = message.data['type'] == 'voice_call';
    if (isVoiceCall) {
      await _showIncomingCall(message.data);
      return;
    }

    final isVoiceCallEnded = message.data['type'] == 'voice_call_ended';
    if (isVoiceCallEnded) {
      final callId = message.data['callId'];
      if (callId is String && callId.isNotEmpty) {
        await _finishCallKitCall(callId);
      }
      return;
    }

    final title = message.notification?.title ?? message.data['title'] ?? 'Pesan baru';
    final body = message.notification?.body ?? message.data['body'] ?? message.data['text'] ?? '';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _chatChannelId,
        'Chat Notification',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        autoCancel: true,
      ),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _showIncomingCall(Map<String, dynamic> data) async {
    final callId = data['callId'];
    final roomId = data['roomId'];
    final callerId = data['callerId'];
    final callerName = data['callerName'] ?? data['title'] ?? 'Panggilan suara';

    if (callId is! String || callId.isEmpty || roomId is! String || callerId is! String) {
      return;
    }

    final shouldShowCall = await _shouldShowIncomingCall(callId);
    if (!shouldShowCall) {
      await _finishCallKitCall(callId);
      return;
    }

    await FlutterCallkitIncoming.endAllCalls();

    final closeAppOnEnd = _isAppNotForeground();
    _closeAppAfterCallById[callId] = closeAppOnEnd;

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName.toString(),
      appName: 'ChatKuy',
      handle: callerName.toString(),
      type: 0,
      duration: 30000,
      textAccept: 'Terima',
      textDecline: 'Tolak',
      extra: Map<String, dynamic>.from(data),
      missedCallNotification: const NotificationParams(
        showNotification: true,
        subtitle: 'Panggilan tak terjawab',
        callbackText: 'Telepon balik',
      ),
      callingNotification: const NotificationParams(
        showNotification: true,
        subtitle: 'Panggilan berlangsung',
        callbackText: 'Akhiri',
      ),
      android: const AndroidParams(
        isCustomNotification: true,
        isCustomSmallExNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#101820',
        actionColor: '#0098FF',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Incoming Call',
        missedCallNotificationChannelName: 'Missed Call',
        isShowCallID: false,
        isShowFullLockedScreen: true,
        isImportant: true,
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    _lastIncomingCall = (
      data: Map<String, dynamic>.from(data),
      autoAccept: false,
      closeAppOnEnd: closeAppOnEnd,
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    _watchIncomingCallStatus(callId);
  }

  static Future<bool> _shouldShowIncomingCall(String callId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(FirebaseCollections.calls).doc(callId).get();
      final status = snapshot.data()?[CallField.status];
      if (_isClosedCallStatus(status)) return false;
      return status == null || status == CallStatus.ringing;
    } catch (_) {
      return true;
    }
  }

  static void _watchIncomingCallStatus(String callId) {
    _callStatusSubscriptions[callId]?.cancel();
    _callStatusSubscriptions[callId] = FirebaseFirestore.instance
        .collection(FirebaseCollections.calls)
        .doc(callId)
        .snapshots()
        .listen((snapshot) async {
      final status = snapshot.data()?[CallField.status];
      if (_isClosedCallStatus(status)) {
        await _finishCallKitCall(callId);
        return;
      }

      if (status == CallStatus.active) {
        final subscription = _callStatusSubscriptions.remove(callId);
        await subscription?.cancel();
      }
    }, onError: (Object error) {
      debugPrint('Incoming call status listener failed: $error');
    });
  }

  static bool _isClosedCallStatus(dynamic status) {
    return status == CallStatus.declined || status == CallStatus.ended || status == CallStatus.missed;
  }

  static void _listenCallKitEvents() {
    if (_isCallKitListenerAttached) return;
    _isCallKitListenerAttached = true;

    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;

      final data = _extractCallKitData(event);
      debugPrint('CallKit event: ${event.event} data=$data');

      switch (event.event) {
        case Event.actionCallAccept:
          final closeAppOnEnd = _closeAppOnEndFor(data);
          _lastIncomingCall = (
            data: data,
            autoAccept: true,
            closeAppOnEnd: closeAppOnEnd,
          );
          _openVoiceCall(
            data,
            autoAccept: true,
            closeAppOnEnd: closeAppOnEnd,
          );
          break;
        case Event.actionCallDecline:
        case Event.actionCallTimeout:
          await _declineVoiceCall(data);
          break;
        case Event.actionCallEnded:
          await _endVoiceCall(data);
          break;
        default:
          break;
      }
    });
  }

  static Map<String, dynamic> _extractCallKitData(CallEvent event) {
    final body = event.body;
    if (body is! Map) return _lastIncomingCall?.data ?? {};

    final mappedBody = Map<String, dynamic>.from(body);
    final extra = mappedBody['extra'];
    if (extra is Map) {
      return Map<String, dynamic>.from(extra);
    }

    final nestedBody = mappedBody['body'];
    if (nestedBody is Map) {
      final nestedExtra = nestedBody['extra'];
      if (nestedExtra is Map) {
        return Map<String, dynamic>.from(nestedExtra);
      }
      final nested = Map<String, dynamic>.from(nestedBody);
      if (_hasVoiceCallKeys(nested)) return nested;
    }

    final data = mappedBody['data'];
    if (data is Map) {
      final dataExtra = data['extra'];
      if (dataExtra is Map) {
        return Map<String, dynamic>.from(dataExtra);
      }
      final mappedData = Map<String, dynamic>.from(data);
      if (_hasVoiceCallKeys(mappedData)) return mappedData;
    }

    if (!_hasVoiceCallKeys(mappedBody)) {
      return _lastIncomingCall?.data ?? mappedBody;
    }

    return mappedBody;
  }

  static Map<String, dynamic> _extractCallKitMapData(
    Map<String, dynamic> data,
  ) {
    final extra = data['extra'];
    if (extra is Map) {
      return Map<String, dynamic>.from(extra);
    }

    final nestedBody = data['body'];
    if (nestedBody is Map) {
      final nested = Map<String, dynamic>.from(nestedBody);
      final nestedExtra = nested['extra'];
      if (nestedExtra is Map) {
        return Map<String, dynamic>.from(nestedExtra);
      }
      if (_hasVoiceCallKeys(nested)) return nested;
    }

    if (_hasVoiceCallKeys(data)) return data;
    return _lastIncomingCall?.data ?? data;
  }

  static bool _hasVoiceCallKeys(Map<String, dynamic> data) {
    return data['callId'] is String && data['roomId'] is String && data['callerId'] is String;
  }

  static Future<void> processPendingLaunchNotification() async {
    final response = _pendingLaunchResponse;
    if (response != null) {
      _pendingLaunchResponse = null;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _handleNotificationResponse(response);
    }

    final voiceCall = _pendingVoiceCall;
    if (voiceCall != null) {
      _pendingVoiceCall = null;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _openVoiceCall(
        voiceCall.data,
        autoAccept: voiceCall.autoAccept,
        closeAppOnEnd: voiceCall.closeAppOnEnd,
      );
    }

    await processAcceptedCallKitCalls();
  }

  static Future<VoiceCallArgument?> takeInitialAcceptedCallArgument() async {
    final voiceCall = _pendingVoiceCall;
    if (voiceCall != null) {
      _pendingVoiceCall = null;
      return _voiceCallArgumentFromData(
        voiceCall.data,
        autoAccept: voiceCall.autoAccept,
        closeAppOnEnd: voiceCall.closeAppOnEnd,
      );
    }

    final activeCalls = await FlutterCallkitIncoming.activeCalls();
    debugPrint('CallKit initial activeCalls: $activeCalls');
    if (activeCalls is! List) return null;

    for (final call in activeCalls) {
      if (call is! Map) continue;

      final callMap = Map<String, dynamic>.from(call);
      if (callMap['isAccepted'] != true) continue;

      final data = _extractCallKitMapData(callMap);
      if (!_hasVoiceCallKeys(data)) continue;

      final callId = data['callId']?.toString();
      if (callId != null) _handledAcceptedCallIds.add(callId);

      return _voiceCallArgumentFromData(
        data,
        autoAccept: true,
        closeAppOnEnd: _closeAppOnEndFor(data, fallback: true),
      );
    }

    return null;
  }

  static Future<void> processAcceptedCallKitCalls() async {
    final activeCalls = await FlutterCallkitIncoming.activeCalls();
    debugPrint('CallKit activeCalls: $activeCalls');

    if (activeCalls is! List) return;

    for (final call in activeCalls) {
      if (call is! Map) continue;

      final callMap = Map<String, dynamic>.from(call);
      final isAccepted = callMap['isAccepted'] == true;
      if (!isAccepted) continue;

      final callId = callMap['id']?.toString();
      if (callId == null || _handledAcceptedCallIds.contains(callId)) {
        continue;
      }

      final data = _extractCallKitMapData(callMap);
      if (!_hasVoiceCallKeys(data)) continue;

      _handledAcceptedCallIds.add(callId);
      _openVoiceCall(
        data,
        autoAccept: true,
        closeAppOnEnd: _closeAppOnEndFor(data),
      );
      break;
    }
  }

  static Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
    final type = data['type'];
    debugPrint(
      'LocalNotification response: action=${response.actionId} type=$type',
    );

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

    try {
      await FirebaseFirestore.instance.collection(FirebaseCollections.calls).doc(callId).update({
        CallField.status: CallStatus.declined,
        CallField.endedAt: FieldValue.serverTimestamp(),
      });
    } finally {
      await _finishCallKitCall(callId);
    }
  }

  static Future<void> _endVoiceCall(Map<String, dynamic> data) async {
    final callId = data['callId'];
    if (callId is! String || callId.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection(FirebaseCollections.calls).doc(callId).update({
        CallField.status: CallStatus.ended,
        CallField.endedAt: FieldValue.serverTimestamp(),
      });
    } finally {
      await _finishCallKitCall(callId);
    }
  }

  static Future<void> _finishCallKitCall(String callId) async {
    try {
      await FlutterCallkitIncoming.endCall(callId);
      await FlutterCallkitIncoming.endAllCalls();
    } finally {
      final subscription = _callStatusSubscriptions.remove(callId);
      await subscription?.cancel();
      _closeAppAfterCallById.remove(callId);

      final lastCallId = _lastIncomingCall?.data['callId'];
      if (lastCallId == callId) _lastIncomingCall = null;

      final pendingCallId = _pendingVoiceCall?.data['callId'];
      if (pendingCallId == callId) _pendingVoiceCall = null;
    }
  }

  static void _openVoiceCall(
    Map<String, dynamic> data, {
    bool autoAccept = false,
    bool closeAppOnEnd = false,
  }) {
    final argument = _voiceCallArgumentFromData(
      data,
      autoAccept: autoAccept,
      closeAppOnEnd: closeAppOnEnd,
    );
    if (argument == null) {
      _pendingVoiceCall = (
        data: data,
        autoAccept: autoAccept,
        closeAppOnEnd: closeAppOnEnd,
      );
      return;
    }

    if (autoAccept) {
      _handledAcceptedCallIds.add(argument.callId ?? '');
    }

    if (Get.key.currentState == null) {
      _pendingVoiceCall = (
        data: data,
        autoAccept: autoAccept,
        closeAppOnEnd: closeAppOnEnd,
      );
      return;
    }

    Get.toNamed(
      AppRouteName.VOICE_CALL_SCREEN,
      arguments: argument,
    );
  }

  static VoiceCallArgument? _voiceCallArgumentFromData(
    Map<String, dynamic> data, {
    required bool autoAccept,
    bool closeAppOnEnd = false,
  }) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final roomId = data['roomId'];
    final callId = data['callId'];
    final callerId = data['callerId'];
    final callerName = data['callerName'] ?? 'Panggilan suara';

    if (currentUid == null || roomId is! String || callId is! String || callerId is! String) {
      return null;
    }

    return VoiceCallArgument(
      roomId: roomId,
      currentUid: currentUid,
      targetUid: callerId,
      targetName: callerName.toString(),
      callId: callId,
      isCaller: false,
      autoAccept: autoAccept,
      closeAppOnEnd: closeAppOnEnd,
    );
  }

  static bool _closeAppOnEndFor(
    Map<String, dynamic> data, {
    bool? fallback,
  }) {
    final callId = data['callId'];
    if (callId is String) {
      final closeAppOnEnd = _closeAppAfterCallById[callId];
      if (closeAppOnEnd != null) return closeAppOnEnd;
    }

    return fallback ?? _isAppNotForeground();
  }

  static bool _isAppNotForeground() {
    return WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;
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
