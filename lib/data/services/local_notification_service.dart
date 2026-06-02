import 'dart:async';
import 'dart:convert';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/repositories/local_notification_repository.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:chatkuy/ui/chat/call/call_argument.dart';
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
  static const _acceptCallAction = 'accept_voice_call';
  static const _declineCallAction = 'decline_voice_call';
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
  })? _pendingCall;
  static bool _isCallKitListenerAttached = false;
  static bool _isProcessingPendingLaunchNotification = false;
  static final Set<String> _handledAcceptedCallIds = {};
  static final Set<String> _finishedCallIds = {};
  static DateTime? _lastCallKitFinishedAt;
  static final Map<String, bool> _closeAppAfterCallById = {};
  static final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _callStatusSubscriptions = {};

  @override
  Future<void> init() async {
    await _initPlugin(handleLaunchDetails: true);
    _listenCallKitEvents();
  }

  static Future<void> showFromBackground(RemoteMessage message) async {
    await _initPlugin(handleLaunchDetails: false);
    _listenCallKitEvents();
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
      description: 'Notification for incoming calls',
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

    if (handleLaunchDetails) unawaited(_requestRuntimePermissions());
  }

  static Future<void> _requestRuntimePermissions() async {
    try {
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
    } catch (error, stackTrace) {
      await AppErrorLogger.recordError(
        error,
        stackTrace,
        reason: 'Request notification permissions failed',
        showBottomSheet: false,
      );
    }
  }

  @override
  Future<void> show(RemoteMessage message) async {
    if (message.data['type'] == 'chat') {
      await markChatMessageDeliveredFromPayload(message.data);
    }

    final isCall = message.data['type'] == 'voice_call' || message.data['type'] == 'video_call';
    if (isCall) {
      await _showIncomingCall(message.data);
      return;
    }

    final isCallEnded = message.data['type'] == 'voice_call_ended' || message.data['type'] == 'video_call_ended';
    if (isCallEnded) {
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

  static Future<void> markChatMessageDeliveredFromPayload(
    Map<String, dynamic> data,
  ) async {
    final roomId = data['roomId'];
    final messageId = data['messageId'];
    final receiverId = data['receiverId'];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (roomId is! String || roomId.isEmpty || messageId is! String || messageId.isEmpty) {
      return;
    }

    final deliveredUid = currentUid ?? (receiverId is String && receiverId.isNotEmpty ? receiverId : null);

    if (deliveredUid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.chatRooms)
          .doc(roomId)
          .collection(FirestoreCollection.messages)
          .doc(messageId)
          .update({
        '${MessageField.deliveredTo}.$deliveredUid': true,
      });
    } catch (error, stackTrace) {
      await AppErrorLogger.recordError(
        error,
        stackTrace,
        reason: 'Mark chat notification delivered failed',
        context: {
          'room_id': roomId,
          'message_id': messageId,
          'current_uid': currentUid,
        },
        showBottomSheet: false,
      );
    }
  }

  static Future<void> _showIncomingCall(Map<String, dynamic> data) async {
    final callId = data['callId'];
    final roomId = data['roomId'];
    final callerId = data['callerId'];
    final isVideoCall = _isVideoCallPayload(data);
    final callerName = data['callerName'] ?? data['title'] ?? (isVideoCall ? 'Panggilan video' : 'Panggilan suara');

    if (callId is! String || callId.isEmpty || roomId is! String || callerId is! String) {
      return;
    }

    final callerAvatar = await _resolveCallerAvatar(data);

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
      avatar: callerAvatar,
      handle: callerName.toString(),
      type: isVideoCall ? 1 : 0,
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
      ios: IOSParams(
        handleType: 'generic',
        supportsVideo: isVideoCall,
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
    await _markCallRinging(callId);
    _watchIncomingCallStatus(callId);
  }

  static Future<void> _markCallRinging(String callId) async {
    try {
      final callRef = FirebaseFirestore.instance.collection(FirebaseCollections.calls).doc(callId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(callRef);
        final status = snapshot.data()?[CallField.status];
        if (status == null || status == CallStatus.calling) {
          transaction.update(callRef, {CallField.status: CallStatus.ringing});
        }
      });
    } catch (error, stackTrace) {
      await AppErrorLogger.recordError(
        error,
        stackTrace,
        reason: 'Mark incoming call ringing failed',
        context: {'call_id': callId},
        showBottomSheet: false,
      );
    }
  }

  static Future<String?> _resolveCallerAvatar(Map<String, dynamic> data) async {
    final payloadAvatar = data['callerPhotoUrl'];
    final payloadAvatarUrl = _callKitAvatarUrl(payloadAvatar);
    if (payloadAvatarUrl != null) return payloadAvatarUrl;

    final callerId = data['callerId'];
    if (callerId is! String || callerId.isEmpty) return null;

    try {
      final callerSnap = await FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(callerId).get();
      return _callKitAvatarUrl(callerSnap.data()?[FriendField.photoUrl]);
    } catch (error) {
      debugPrint('Resolve caller avatar failed: $error');
      return null;
    }
  }

  static String? _callKitAvatarUrl(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return value;
  }

  static Future<bool> _shouldShowIncomingCall(String callId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(FirebaseCollections.calls).doc(callId).get();
      final status = snapshot.data()?[CallField.status];
      if (_isClosedCallStatus(status)) return false;
      return status == null || status == CallStatus.calling || status == CallStatus.ringing;
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
          _openCall(
            data,
            autoAccept: true,
            closeAppOnEnd: closeAppOnEnd,
          );
          break;
        case Event.actionCallDecline:
        case Event.actionCallTimeout:
          await _declineCall(data);
          break;
        case Event.actionCallEnded:
          await _endCall(data);
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
      if (_hasCallKeys(nested)) return nested;
    }

    final data = mappedBody['data'];
    if (data is Map) {
      final dataExtra = data['extra'];
      if (dataExtra is Map) {
        return Map<String, dynamic>.from(dataExtra);
      }
      final mappedData = Map<String, dynamic>.from(data);
      if (_hasCallKeys(mappedData)) return mappedData;
    }

    if (!_hasCallKeys(mappedBody)) {
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
      if (_hasCallKeys(nested)) return nested;
    }

    if (_hasCallKeys(data)) return data;
    return _lastIncomingCall?.data ?? data;
  }

  static bool _hasCallKeys(Map<String, dynamic> data) {
    return data['callId'] is String && data['roomId'] is String && data['callerId'] is String;
  }

  static Future<void> processPendingLaunchNotification() async {
    if (_isInCallKitFinishCooldown()) return;
    if (_isProcessingPendingLaunchNotification) return;

    _isProcessingPendingLaunchNotification = true;
    try {
      final response = _pendingLaunchResponse;
      if (response != null) {
        _pendingLaunchResponse = null;
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await _handleNotificationResponse(response);
      }

      final call = _pendingCall;
      if (call != null) {
        _pendingCall = null;
        await Future<void>.delayed(const Duration(milliseconds: 300));
        _openCall(
          call.data,
          autoAccept: call.autoAccept,
          closeAppOnEnd: call.closeAppOnEnd,
        );
      }

      await processAcceptedCallKitCalls();
    } finally {
      _isProcessingPendingLaunchNotification = false;
    }
  }

  static Future<CallArgument?> takeInitialAcceptedCallArgument() async {
    final call = _pendingCall;
    if (call != null) {
      _pendingCall = null;
      return _callArgumentFromData(
        call.data,
        autoAccept: call.autoAccept,
        closeAppOnEnd: call.closeAppOnEnd,
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
      if (!_hasCallKeys(data)) continue;

      final callId = data['callId']?.toString();
      if (callId != null) {
        final shouldOpen = await _shouldOpenAcceptedCall(callId);
        if (!shouldOpen) continue;
        _handledAcceptedCallIds.add(callId);
      }

      return _callArgumentFromData(
        data,
        autoAccept: true,
        closeAppOnEnd: _closeAppOnEndFor(data, fallback: true),
      );
    }

    return null;
  }

  static Future<void> processAcceptedCallKitCalls() async {
    if (_isInCallKitFinishCooldown()) return;

    final activeCalls = await FlutterCallkitIncoming.activeCalls();
    debugPrint('CallKit activeCalls: $activeCalls');

    if (activeCalls is! List) return;

    for (final call in activeCalls) {
      if (call is! Map) continue;

      final callMap = Map<String, dynamic>.from(call);
      final isAccepted = callMap['isAccepted'] == true;
      if (!isAccepted) continue;

      final callId = callMap['id']?.toString();
      if (callId == null || _finishedCallIds.contains(callId) || _handledAcceptedCallIds.contains(callId)) {
        continue;
      }

      final data = _extractCallKitMapData(callMap);
      if (!_hasCallKeys(data)) continue;

      final shouldOpen = await _shouldOpenAcceptedCall(callId);
      if (!shouldOpen) continue;

      _handledAcceptedCallIds.add(callId);
      _openCall(
        data,
        autoAccept: true,
        closeAppOnEnd: _closeAppOnEndFor(data),
      );
      break;
    }
  }

  static Future<bool> _shouldOpenAcceptedCall(String callId) async {
    if (_finishedCallIds.contains(callId)) return false;

    try {
      final snapshot = await FirebaseFirestore.instance.collection(FirebaseCollections.calls).doc(callId).get();
      final status = snapshot.data()?[CallField.status];
      if (_isClosedCallStatus(status)) {
        await _finishCallKitCall(callId);
        return false;
      }
      return true;
    } catch (error) {
      debugPrint('Check accepted call status failed: $error');
      return true;
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

    if (type == 'voice_call' || type == 'video_call') {
      if (response.actionId == _declineCallAction) {
        await _declineCall(data);
        return;
      }

      _openCall(
        data,
        autoAccept: response.actionId == _acceptCallAction,
      );
      return;
    }

    if (type == 'chat') {
      _openChatRoom(data);
    }
  }

  static Future<void> _declineCall(Map<String, dynamic> data) async {
    final callId = data['callId'];
    if (callId is! String || callId.isEmpty) return;

    try {
      await _finishRemoteCall(
        callId: callId,
        status: CallStatus.declined,
      );
    } finally {
      await _finishCallKitCall(callId);
    }
  }

  static Future<void> _endCall(Map<String, dynamic> data) async {
    final callId = data['callId'];
    if (callId is! String || callId.isEmpty) return;

    try {
      await _finishRemoteCall(
        callId: callId,
        status: CallStatus.ended,
      );
    } finally {
      await _finishCallKitCall(callId);
    }
  }

  static Future<void> _finishRemoteCall({
    required String callId,
    required String status,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final callRef = firestore.collection(FirebaseCollections.calls).doc(callId);
    final callSnap = await callRef.get();
    final callData = callSnap.data();

    if (callData == null) {
      await callRef.update({
        CallField.status: status,
        CallField.endedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    final roomId = callData[CallField.roomId] as String?;
    final callType = callData[CallField.type] as String? ?? 'voice';
    final durationSeconds = _callDurationSeconds(callData[CallField.answeredAt]);
    final text = _callMessageText(
      status,
      callType,
      durationSeconds: durationSeconds,
    );
    final batch = firestore.batch();

    batch.update(callRef, {
      CallField.status: status,
      CallField.endedAt: FieldValue.serverTimestamp(),
    });

    if (roomId != null && roomId.isNotEmpty) {
      final chatRoomRef = firestore.collection(FirebaseCollections.chatRooms).doc(roomId);
      final messageRef = chatRoomRef.collection(FirestoreCollection.messages).doc(callId);

      batch.set(
        messageRef,
        {
          MessageField.text: text,
          MessageField.callStatus: status,
          MessageField.callType: callType,
          MessageField.callDurationSeconds: durationSeconds,
        },
        SetOptions(merge: true),
      );

      batch.update(chatRoomRef, {
        ChatRoomField.lastMessage: text,
        ChatRoomField.lastMessageAt: FieldValue.serverTimestamp(),
        ChatRoomField.lastSenderId: callData[CallField.callerId],
        ChatRoomField.type: 'call',
      });
    }

    await batch.commit();
  }

  static int _callDurationSeconds(dynamic answeredAt) {
    if (answeredAt is! Timestamp) return 0;
    final duration = DateTime.now().difference(answeredAt.toDate()).inSeconds;
    return duration < 0 ? 0 : duration;
  }

  static String _callMessageText(
    String status,
    String callType, {
    int durationSeconds = 0,
  }) {
    final label = callType == 'video' ? 'Panggilan video' : 'Panggilan suara';
    if (status == CallStatus.declined) return '$label ditolak';
    if (status == CallStatus.missed) return '$label tak terjawab';
    if (status == CallStatus.calling || status == CallStatus.ringing) {
      return '$label berlangsung';
    }
    if (durationSeconds > 0) return '$label selesai';
    return '$label berakhir';
  }

  static Future<void> _finishCallKitCall(String callId) async {
    _lastCallKitFinishedAt = DateTime.now();
    _finishedCallIds.add(callId);
    _handledAcceptedCallIds.add(callId);

    try {
      await FlutterCallkitIncoming.endCall(callId);
      await FlutterCallkitIncoming.endAllCalls();
    } finally {
      final subscription = _callStatusSubscriptions.remove(callId);
      await subscription?.cancel();
      _closeAppAfterCallById.remove(callId);

      final lastCallId = _lastIncomingCall?.data['callId'];
      if (lastCallId == callId) _lastIncomingCall = null;

      final pendingCallId = _pendingCall?.data['callId'];
      if (pendingCallId == callId) _pendingCall = null;
    }
  }

  static Future<void> finishCallKitCall(String callId) {
    return _finishCallKitCall(callId);
  }

  static void _openCall(
    Map<String, dynamic> data, {
    bool autoAccept = false,
    bool closeAppOnEnd = false,
  }) {
    final callId = data['callId'];
    if (callId is String && _finishedCallIds.contains(callId)) {
      return;
    }

    final argument = _callArgumentFromData(
      data,
      autoAccept: autoAccept,
      closeAppOnEnd: closeAppOnEnd,
    );
    if (argument == null) {
      _pendingCall = (
        data: data,
        autoAccept: autoAccept,
        closeAppOnEnd: closeAppOnEnd,
      );
      return;
    }

    if (autoAccept) {
      _handledAcceptedCallIds.add(argument.callId ?? '');
    }

    if (Get.currentRoute == AppRouteName.CALL_SCREEN) {
      return;
    }

    if (Get.key.currentState == null) {
      _pendingCall = (
        data: data,
        autoAccept: autoAccept,
        closeAppOnEnd: closeAppOnEnd,
      );
      return;
    }

    Get.toNamed(
      AppRouteName.CALL_SCREEN,
      arguments: argument,
    );
  }

  static bool _isInCallKitFinishCooldown() {
    final finishedAt = _lastCallKitFinishedAt;
    if (finishedAt == null) return false;
    return DateTime.now().difference(finishedAt) < const Duration(seconds: 2);
  }

  static CallArgument? _callArgumentFromData(
    Map<String, dynamic> data, {
    required bool autoAccept,
    bool closeAppOnEnd = false,
  }) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final roomId = data['roomId'];
    final callId = data['callId'];
    final callerId = data['callerId'];
    final isVideoCall = _isVideoCallPayload(data);
    final callerName = data['callerName'] ?? (isVideoCall ? 'Panggilan video' : 'Panggilan suara');

    if (currentUid == null || roomId is! String || callId is! String || callerId is! String) {
      return null;
    }

    return CallArgument(
      roomId: roomId,
      currentUid: currentUid,
      targetUid: callerId,
      targetName: callerName.toString(),
      callId: callId,
      isCaller: false,
      autoAccept: autoAccept,
      closeAppOnEnd: closeAppOnEnd,
      isVideoCall: isVideoCall,
    );
  }

  static bool _isVideoCallPayload(Map<String, dynamic> data) {
    return data['type'] == 'video_call' || data['callType'] == 'video' || data[CallField.type] == 'video';
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
