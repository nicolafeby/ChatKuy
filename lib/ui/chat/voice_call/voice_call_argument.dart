class VoiceCallArgument {
  const VoiceCallArgument({
    required this.roomId,
    required this.currentUid,
    required this.targetUid,
    required this.targetName,
    required this.isCaller,
    this.currentUserName,
    this.callId,
    this.autoAccept = false,
    this.closeAppOnEnd = false,
  });

  final String roomId;
  final String currentUid;
  final String targetUid;
  final String targetName;
  final bool isCaller;
  final String? currentUserName;
  final String? callId;
  final bool autoAccept;
  final bool closeAppOnEnd;
}
