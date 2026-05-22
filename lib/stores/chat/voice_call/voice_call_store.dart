import 'dart:async';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:chatkuy/ui/chat/voice_call/voice_call_argument.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mobx/mobx.dart';
import 'package:permission_handler/permission_handler.dart';

part 'voice_call_store.g.dart';

class VoiceCallStore = _VoiceCallStore with _$VoiceCallStore;

abstract class _VoiceCallStore with Store {
  _VoiceCallStore({required this.callRepository});

  final CallRepository callRepository;
  final Set<String> _addedCandidateIds = {};
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  VoiceCallArgument? argument;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription? _callSubscription;
  StreamSubscription? _candidateSubscription;
  String? _callId;
  bool _isEnding = false;
  bool _remoteDescriptionSet = false;
  VoidCallback? _onClose;
  void Function(String message)? _onMessage;

  @observable
  bool isMuted = false;

  @observable
  bool isSpeakerOn = true;

  @observable
  bool isConnecting = true;

  @observable
  bool hasRemoteAudio = false;

  @observable
  String statusText = 'Menghubungkan...';

  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  Future<void> init({
    required VoiceCallArgument argument,
    VoidCallback? onClose,
    void Function(String message)? onMessage,
  }) async {
    this.argument = argument;
    _onClose = onClose;
    _onMessage = onMessage;

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

      await Helper.setSpeakerphoneOn(isSpeakerOn);

      _peerConnection = await createPeerConnection(_configuration);
      _peerConnection?.onIceConnectionState = _handleIceState;
      _peerConnection?.onConnectionState =
          (state) => debugPrint('VoiceCall peer state: $state');

      for (final track in _localStream!.getTracks()) {
        await _peerConnection?.addTrack(track, _localStream!);
      }

      _peerConnection?.onIceCandidate = (candidate) {
        final callId = _callId;
        if (callId == null || candidate.candidate == null) return;

        callRepository.addCandidate(
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
        debugPrint(
          'VoiceCall remote track: kind=${event.track.kind}, streams=${event.streams.length}',
        );
        _markRemoteAudioReceived();
      };

      if (argument.isCaller) {
        await _startOutgoingCall(argument);
      } else {
        await _answerIncomingCall(argument);
      }
    } catch (e) {
      _showMessage('Gagal memulai panggilan: $e');
      await endCall(updateRemote: true);
    }
  }

  Future<void> _startOutgoingCall(VoiceCallArgument argument) async {
    final callRef = await callRepository.createCall(
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
    await callRepository.setOffer(
      callId: callRef.id,
      offer: {
        'type': offer.type,
        'sdp': offer.sdp,
      },
    );

    _setStatus('Memanggil ${argument.targetName}...');
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

    final callSnap = await callRepository.watchCall(callId).first;
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
    _remoteDescriptionSet = true;
    await _flushPendingRemoteCandidates();

    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(answer);
    await callRepository.setAnswer(
      callId: callId,
      answer: {
        'type': answer.type,
        'sdp': answer.sdp,
      },
    );

    _setConnectingStatus('Menyambungkan audio...');
  }

  void _listenCall() {
    final callId = _callId;
    final currentArgument = argument;
    if (callId == null || currentArgument == null) return;

    _callSubscription = callRepository.watchCall(callId).listen((snapshot) {
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
      if (currentArgument.isCaller && answer is Map) {
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
          _remoteDescriptionSet = true;
          await _flushPendingRemoteCandidates();
          _setConnectingStatus('Menyambungkan audio...');
        });
      }
    });
  }

  void _listenRemoteCandidates() {
    final callId = _callId;
    final currentArgument = argument;
    if (callId == null || currentArgument == null) return;

    _candidateSubscription = callRepository
        .watchRemoteCandidates(
      callId: callId,
      isCaller: currentArgument.isCaller,
    )
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        if (!_addedCandidateIds.add(change.doc.id)) continue;

        final data = change.doc.data();
        final candidate = data?['candidate'];
        if (candidate is! String || candidate.isEmpty) continue;

        _addRemoteCandidate(
          RTCIceCandidate(
            candidate,
            data?['sdpMid'] as String?,
            (data?['sdpMLineIndex'] as num?)?.toInt(),
          ),
        );
      }
    });
  }

  Future<void> _addRemoteCandidate(RTCIceCandidate candidate) async {
    final peerConnection = _peerConnection;
    if (peerConnection == null) return;

    if (!_remoteDescriptionSet) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }

    try {
      await peerConnection.addCandidate(candidate);
    } catch (e) {
      debugPrint('VoiceCall addCandidate failed: $e');
    }
  }

  Future<void> _flushPendingRemoteCandidates() async {
    final peerConnection = _peerConnection;
    if (peerConnection == null || _pendingRemoteCandidates.isEmpty) return;

    final candidates = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();

    for (final candidate in candidates) {
      try {
        await peerConnection.addCandidate(candidate);
      } catch (e) {
        debugPrint('VoiceCall flush candidate failed: $e');
      }
    }
  }

  @action
  Future<void> toggleMute() async {
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    final nextMuted = !isMuted;
    for (final track in audioTracks) {
      track.enabled = !nextMuted;
    }
    isMuted = nextMuted;
  }

  @action
  Future<void> toggleSpeaker() async {
    final nextSpeaker = !isSpeakerOn;
    await Helper.setSpeakerphoneOn(nextSpeaker);
    isSpeakerOn = nextSpeaker;
  }

  @action
  Future<void> endCall({bool updateRemote = true}) async {
    if (_isEnding) return;
    _isEnding = true;

    final callId = _callId;
    if (updateRemote && callId != null) {
      await callRepository.endCall(callId);
    }
    _close();
  }

  @action
  void _handleIceState(RTCIceConnectionState state) {
    debugPrint('VoiceCall ICE state: $state');

    if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
      isConnecting = false;
      statusText = 'Terhubung';
    } else if (state == RTCIceConnectionState.RTCIceConnectionStateChecking) {
      isConnecting = true;
      statusText = 'Menyambungkan audio...';
    } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      isConnecting = false;
      statusText = 'Audio gagal tersambung';
    } else if (state ==
        RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
      statusText = 'Koneksi audio terputus';
    }
  }

  @action
  void _markRemoteAudioReceived() {
    hasRemoteAudio = true;
    statusText = 'Audio diterima';
  }

  @action
  void _setStatus(String text) {
    statusText = text;
  }

  @action
  void _setConnectingStatus(String text) {
    statusText = text;
    isConnecting = true;
  }

  void _showMessage(String message) {
    _onMessage?.call(message);
  }

  void _close() {
    _onClose?.call();
  }

  @action
  void dispose() {
    _callSubscription?.cancel();
    _candidateSubscription?.cancel();
    _peerConnection?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
  }
}
