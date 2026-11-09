class CallNotificationPayload {
  const CallNotificationPayload({
    required this.callId,
    required this.roomId,
    required this.callerId,
    required this.isVideoCall,
    this.callerName,
    this.callerPhotoUrl,
  });

  final String callId;
  final String roomId;
  final String callerId;
  final bool isVideoCall;
  final String? callerName;
  final String? callerPhotoUrl;

  static CallNotificationPayload? tryParse(Map<String, dynamic> data) {
    final callId = _requiredString(data['callId']);
    final roomId = _requiredString(data['roomId']);
    final callerId = _requiredString(data['callerId']);
    if (callId == null || roomId == null || callerId == null) return null;

    return CallNotificationPayload(
      callId: callId,
      roomId: roomId,
      callerId: callerId,
      isVideoCall: data['type'] == 'video_call' ||
          data['callType'] == 'video' ||
          data['type'] == 'video',
      callerName: _optionalString(data['callerName'] ?? data['title']),
      callerPhotoUrl: _optionalString(data['callerPhotoUrl']),
    );
  }

  static String? _requiredString(dynamic value) {
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  static String? _optionalString(dynamic value) => _requiredString(value);
}

abstract final class CallKitPayloadExtractor {
  static Map<String, dynamic> extract(
    Map<String, dynamic> data, {
    Map<String, dynamic>? fallback,
  }) {
    final extra = data['extra'];
    if (extra is Map) return Map<String, dynamic>.from(extra);

    for (final key in const ['body', 'data']) {
      final candidate = data[key];
      if (candidate is! Map) continue;
      final mapped = Map<String, dynamic>.from(candidate);
      final nestedExtra = mapped['extra'];
      if (nestedExtra is Map) return Map<String, dynamic>.from(nestedExtra);
      if (hasRequiredKeys(mapped)) return mapped;
    }

    if (hasRequiredKeys(data)) return data;
    return fallback ?? data;
  }

  static bool hasRequiredKeys(Map<String, dynamic> data) {
    return CallNotificationPayload.tryParse(data) != null;
  }
}
