import 'dart:async';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:chatkuy/ui/chat/voice_call/voice_call_argument.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
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
  bool _isDisposed = false;
  bool _remoteDescriptionSet = false;
  bool _usesServerConnectedAt = false;
  DateTime? _connectedAt;
  Timer? _durationTimer;
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

  @observable
  String callDurationText = '00:00';

  @observable
  bool isCallActive = false;

  @observable
  bool isIncomingRinging = false;

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

    if (!argument.isCaller) {
      if (argument.autoAccept) {
        _callId = argument.callId;
        await _startMediaSession(argument);
        return;
      }

      _prepareIncomingCall(argument);
      return;
    }

    await _startMediaSession(argument);
  }

  @action
  void _prepareIncomingCall(VoiceCallArgument argument) {
    if (argument.callId == null) {
      _showMessage('Data panggilan tidak lengkap');
      _close();
      return;
    }

    _callId = argument.callId;
    isIncomingRinging = true;
    isConnecting = false;
    statusText = 'Panggilan suara masuk';
    _listenCall();
  }

  Future<void> _startMediaSession(VoiceCallArgument argument) async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _showMessage('ChatKuy membutuhkan akses mikrofon untuk telepon suara');
      if (!argument.isCaller && _callId != null) {
        await callRepository.declineCall(_callId!);
      }
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
        await _answerIncomingCall();
      }
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Start voice call media session failed',
        context: {
          'room_id': argument.roomId,
          'current_uid': argument.currentUid,
          'target_uid': argument.targetUid,
          'is_caller': argument.isCaller,
        },
      );
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

  Future<void> _answerIncomingCall() async {
    final callId = _callId;
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

    _callSubscription?.cancel();
    _callSubscription = callRepository.watchCall(callId).listen(
      (snapshot) async {
        final data = snapshot.data();
        if (data == null) return;

        final status = data[CallField.status];
        if (status == CallStatus.declined ||
            status == CallStatus.ended ||
            status == CallStatus.missed) {
          _setStatus(_closedStatusText(status));
          _isEnding = true;
          await _teardownCallResources(endCallKit: true);
          _close();
          return;
        }

        if (status == CallStatus.calling && currentArgument.isCaller) {
          _setConnectingStatus('Memanggil');
        } else if (status == CallStatus.ringing && currentArgument.isCaller) {
          _setConnectingStatus('Berdering');
        } else if (status == CallStatus.active) {
          _startCallDuration(
              _dateTimeFromTimestamp(data[CallField.answeredAt]));
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
          }).catchError((error, stackTrace) {
            AppErrorLogger.recordError(
              error,
              stackTrace,
              reason: 'Apply remote voice call answer failed',
              context: {'call_id': callId},
            );
          });
        }
      },
      onError: (error, stackTrace) {
        AppErrorLogger.recordError(
          error,
          stackTrace,
          reason: 'Voice call stream failed',
          context: {'call_id': callId},
        );
      },
    );
  }

  @action
  Future<void> acceptIncomingCall() async {
    final currentArgument = argument;
    if (currentArgument == null || currentArgument.isCaller) return;

    isIncomingRinging = false;
    isConnecting = true;
    statusText = 'Menghubungkan...';
    await _startMediaSession(currentArgument);
  }

  @action
  Future<void> declineIncomingCall() async {
    if (_isEnding) return;
    _isEnding = true;

    final callId = _callId;
    if (callId != null) {
      await callRepository.declineCall(callId);
    }
    await _teardownCallResources(endCallKit: true);
    _close();
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
    }, onError: (error, stackTrace) {
      AppErrorLogger.recordError(
        error,
        stackTrace,
        reason: 'Voice call candidate stream failed',
        context: {'call_id': callId},
      );
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
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Add remote voice call candidate failed',
        context: {'call_id': _callId},
      );
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
      } catch (e, stackTrace) {
        AppErrorLogger.recordError(
          e,
          stackTrace,
          reason: 'Flush pending voice call candidate failed',
          context: {'call_id': _callId},
        );
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
      if (isIncomingRinging) {
        await callRepository.declineCall(callId);
      } else {
        await callRepository.endCall(callId);
      }
    }
    await _teardownCallResources(endCallKit: true);
    _close();
  }

  @action
  void _handleIceState(RTCIceConnectionState state) {
    debugPrint('VoiceCall ICE state: $state');

    if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
      isConnecting = false;
      if (!isCallActive) {
        statusText = 'Terhubung';
      }
      final callId = _callId;
      if (callId != null) {
        FlutterCallkitIncoming.setCallConnected(callId);
      }
    } else if (state == RTCIceConnectionState.RTCIceConnectionStateChecking) {
      isConnecting = true;
      if (!isCallActive) {
        statusText = 'Menyambungkan audio...';
      }
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
    if (!isCallActive) {
      statusText = 'Audio diterima';
    }
  }

  @action
  void _setStatus(String text) {
    statusText = text;
  }

  @action
  void _setConnectingStatus(String text) {
    if (isCallActive) return;
    statusText = text;
    isConnecting = true;
  }

  @action
  void _startCallDuration(DateTime? startedAt) {
    if (isCallActive && _connectedAt != null) {
      if (startedAt != null && !_usesServerConnectedAt) {
        _connectedAt = startedAt;
        _usesServerConnectedAt = true;
        _updateCallDuration();
      }
      return;
    }

    _connectedAt = startedAt ?? DateTime.now();
    _usesServerConnectedAt = startedAt != null;
    isCallActive = true;
    isConnecting = false;
    statusText = 'Terhubung';
    _updateCallDuration();
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCallDuration(),
    );
  }

  @action
  void _updateCallDuration() {
    final startedAt = _connectedAt;
    if (startedAt == null) {
      callDurationText = '00:00';
      return;
    }

    final duration = DateTime.now().difference(startedAt);
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      callDurationText = '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
      return;
    }

    callDurationText = '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  DateTime? _dateTimeFromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  void _showMessage(String message) {
    _onMessage?.call(message);
  }

  void _close() {
    _onClose?.call();
  }

  String _closedStatusText(dynamic status) {
    if (status == CallStatus.declined) return 'Panggilan ditolak';
    if (status == CallStatus.missed) return 'Panggilan tak terjawab';
    return 'Panggilan berakhir';
  }

  Future<void> _teardownCallResources({required bool endCallKit}) async {
    if (_isDisposed) return;
    _isDisposed = true;

    final callSubscription = _callSubscription;
    _callSubscription = null;
    if (callSubscription != null) {
      unawaited(callSubscription.cancel());
    }

    final candidateSubscription = _candidateSubscription;
    _candidateSubscription = null;
    if (candidateSubscription != null) {
      unawaited(candidateSubscription.cancel());
    }

    await _peerConnection?.close();
    _peerConnection = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    _localStream = null;
    _pendingRemoteCandidates.clear();
    _addedCandidateIds.clear();

    final callId = _callId;
    if (endCallKit && callId != null) {
      await FlutterCallkitIncoming.endCall(callId);
      await FlutterCallkitIncoming.endAllCalls();
    }
  }

  @action
  void dispose() {
    unawaited(_teardownCallResources(endCallKit: false));
  }
}
