import 'dart:async';

import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:permission_handler/permission_handler.dart';

class VoiceCallArgument {
  const VoiceCallArgument({
    required this.roomId,
    required this.currentUid,
    required this.targetUid,
    required this.targetName,
    required this.isCaller,
    this.currentUserName,
    this.callId,
  });

  final String roomId;
  final String currentUid;
  final String targetUid;
  final String targetName;
  final bool isCaller;
  final String? currentUserName;
  final String? callId;
}

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final CallRepository _callRepository = getIt<CallRepository>();
  final Set<String> _addedCandidateIds = {};

  VoiceCallArgument? _argument;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription? _callSubscription;
  StreamSubscription? _candidateSubscription;
  String? _callId;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnecting = true;
  bool _hasRemoteAudio = false;
  bool _isEnding = false;
  String _statusText = 'Menghubungkan...';

  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  @override
  void initState() {
    super.initState();
    _argument = Get.arguments as VoiceCallArgument?;
    _initCall();
  }

  Future<void> _initCall() async {
    final argument = _argument;
    if (argument == null) {
      _close();
      return;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _showMessage('ChatKuy membutuhkan akses mikrofon untuk telepon suara');
      _close();
      return;
    }

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      await Helper.setSpeakerphoneOn(_isSpeakerOn);

      _peerConnection = await createPeerConnection(_configuration);
      for (final track in _localStream!.getTracks()) {
        await _peerConnection?.addTrack(track, _localStream!);
      }

      _peerConnection?.onIceCandidate = (candidate) {
        final callId = _callId;
        if (callId == null || candidate.candidate == null) return;

        _callRepository.addCandidate(
          callId: callId,
          isCaller: argument.isCaller,
          candidate: {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      };

      _peerConnection?.onTrack = (event) {
        if (!mounted) return;
        setState(() {
          _hasRemoteAudio = true;
          _isConnecting = false;
          _statusText = 'Terhubung';
        });
      };

      if (argument.isCaller) {
        await _startOutgoingCall(argument);
      } else {
        await _answerIncomingCall(argument);
      }
    } catch (e) {
      _showMessage('Gagal memulai panggilan: $e');
      await _endCall(updateRemote: true);
    }
  }

  Future<void> _startOutgoingCall(VoiceCallArgument argument) async {
    final callRef = await _callRepository.createCall(
      roomId: argument.roomId,
      callerId: argument.currentUid,
      calleeId: argument.targetUid,
      callerName: argument.currentUserName ?? 'ChatKuy',
      calleeName: argument.targetName,
    );

    _callId = callRef.id;
    _listenCall();
    _listenRemoteCandidates();

    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(offer);
    await _callRepository.setOffer(
      callId: callRef.id,
      offer: {
        'type': offer.type,
        'sdp': offer.sdp,
      },
    );

    if (!mounted) return;
    setState(() {
      _statusText = 'Memanggil ${argument.targetName}...';
    });
  }

  Future<void> _answerIncomingCall(VoiceCallArgument argument) async {
    final callId = argument.callId;
    if (callId == null) {
      _showMessage('Data panggilan tidak lengkap');
      _close();
      return;
    }

    _callId = callId;
    _listenCall();
    _listenRemoteCandidates();

    final callSnap = await _callRepository.watchCall(callId).first;
    final data = callSnap.data();
    final offer = data?[CallField.offer];
    if (offer is! Map) {
      _showMessage('Panggilan belum siap');
      _close();
      return;
    }

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(
        offer['sdp'] as String?,
        offer['type'] as String?,
      ),
    );

    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(answer);
    await _callRepository.setAnswer(
      callId: callId,
      answer: {
        'type': answer.type,
        'sdp': answer.sdp,
      },
    );

    if (!mounted) return;
    setState(() {
      _statusText = 'Terhubung';
      _isConnecting = false;
    });
  }

  void _listenCall() {
    final callId = _callId;
    final argument = _argument;
    if (callId == null || argument == null) return;

    _callSubscription = _callRepository.watchCall(callId).listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;

      final status = data[CallField.status];
      if (status == CallStatus.declined ||
          status == CallStatus.ended ||
          status == CallStatus.missed) {
        _close();
        return;
      }

      final answer = data[CallField.answer];
      if (argument.isCaller && answer is Map) {
        final peerConnection = _peerConnection;
        if (peerConnection == null) return;

        peerConnection.getRemoteDescription().then((description) async {
          if (description != null) return;
          await peerConnection.setRemoteDescription(
            RTCSessionDescription(
              answer['sdp'] as String?,
              answer['type'] as String?,
            ),
          );
          if (!mounted) return;
          setState(() {
            _statusText = 'Terhubung';
            _isConnecting = false;
          });
        });
      }
    });
  }

  void _listenRemoteCandidates() {
    final callId = _callId;
    final argument = _argument;
    if (callId == null || argument == null) return;

    _candidateSubscription = _callRepository
        .watchRemoteCandidates(callId: callId, isCaller: argument.isCaller)
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        if (!_addedCandidateIds.add(change.doc.id)) continue;

        final data = change.doc.data();
        final candidate = data?['candidate'];
        if (candidate is! String || candidate.isEmpty) continue;

        _peerConnection?.addCandidate(
          RTCIceCandidate(
            candidate,
            data?['sdpMid'] as String?,
            data?['sdpMLineIndex'] as int?,
          ),
        );
      }
    });
  }

  Future<void> _toggleMute() async {
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    final nextMuted = !_isMuted;
    for (final track in audioTracks) {
      track.enabled = !nextMuted;
    }
    if (!mounted) return;
    setState(() => _isMuted = nextMuted);
  }

  Future<void> _toggleSpeaker() async {
    final nextSpeaker = !_isSpeakerOn;
    await Helper.setSpeakerphoneOn(nextSpeaker);
    if (!mounted) return;
    setState(() => _isSpeakerOn = nextSpeaker);
  }

  Future<void> _endCall({bool updateRemote = true}) async {
    if (_isEnding) return;
    _isEnding = true;

    final callId = _callId;
    if (updateRemote && callId != null) {
      await _callRepository.endCall(callId);
    }
    _close();
  }

  void _close() {
    if (mounted) {
      Get.back();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    Get.snackbar('Telepon suara', message);
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _candidateSubscription?.cancel();
    _peerConnection?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final argument = _argument;

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => _endCall(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  color: Colors.white,
                  tooltip: 'Tutup',
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 52.r,
                backgroundColor: AppColor.primaryColor,
                child: Text(
                  (argument?.targetName.isNotEmpty == true
                          ? argument!.targetName[0]
                          : '?')
                      .toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              22.verticalSpace,
              Text(
                argument?.targetName ?? 'Telepon suara',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              8.verticalSpace,
              Text(
                _hasRemoteAudio ? 'Audio tersambung' : _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
              ),
              if (_isConnecting) ...[
                22.verticalSpace,
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    onTap: _toggleMute,
                  ),
                  _CallControlButton(
                    icon: Icons.call_end,
                    label: 'Akhiri',
                    color: Colors.redAccent,
                    onTap: () => _endCall(),
                  ),
                  _CallControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    label: 'Speaker',
                    onTap: _toggleSpeaker,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final background = color ?? Colors.white.withValues(alpha: 0.14);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 58.r,
              child: Icon(
                icon,
                color: Colors.white,
                size: 26.r,
              ),
            ),
          ),
        ),
        8.verticalSpace,
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
        ),
      ],
    );
  }
}
