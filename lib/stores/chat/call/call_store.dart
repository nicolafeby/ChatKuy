import 'dart:async';

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:chatkuy/data/services/local_notification_service.dart';
import 'package:chatkuy/ui/chat/call/call_argument.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:mobx/mobx.dart';
import 'package:permission_handler/permission_handler.dart';

part 'call_store.g.dart';

class CallStore = _CallStore with _$CallStore;

abstract class _CallStore with Store {
  _CallStore({required this.callRepository});

  final CallRepository callRepository;
  final Set<String> _addedCandidateIds = {};
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  CallArgument? argument;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _localVideoStream;
  StreamSubscription? _callSubscription;
  StreamSubscription? _candidateSubscription;
  String? _callId;
  bool _isEnding = false;
  bool _isDisposed = false;
  bool _remoteDescriptionSet = false;
  bool _videoOfferSent = false;
  bool _videoOfferApplied = false;
  bool _videoAnswerApplied = false;
  bool _videoRenderersInitialized = false;
  bool _usesServerConnectedAt = false;
  DateTime? _connectedAt;
  Timer? _durationTimer;
  VoidCallback? _onClose;
  void Function(String message)? _onMessage;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

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

  @observable
  bool isVideoEnabled = false;

  @observable
  bool isLocalVideoEnabled = false;

  @observable
  bool hasRemoteVideo = false;

  @observable
  bool isVideoUpgradePending = false;

  @observable
  bool isIncomingVideoUpgradeRequest = false;

  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  Future<void> init({
    required CallArgument argument,
    VoidCallback? onClose,
    void Function(String message)? onMessage,
  }) async {
    await _ensureVideoRenderersInitialized();

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
  void _prepareIncomingCall(CallArgument argument) {
    if (argument.callId == null) {
      _showMessage(AppTranslationKey.invalidCallData.tr);
      _close();
      return;
    }

    _callId = argument.callId;
    isIncomingRinging = true;
    isConnecting = false;
    statusText = argument.isVideoCall
        ? AppTranslationKey.incomingVideoCall.tr
        : AppTranslationKey.incomingVoiceCall.tr;
    _listenCall();
  }

  Future<void> _startMediaSession(CallArgument argument) async {
    final resolvedArgument = await _resolveCallType(argument);
    this.argument = resolvedArgument;

    final micGranted = await _ensureCallPermission(
      permission: Permission.microphone,
      deniedMessage: 'ChatKuy membutuhkan akses mikrofon untuk panggilan',
    );
    if (!micGranted) {
      await _closeCallForMissingPermission(
        'Izin mikrofon ditolak, panggilan ditutup',
      );
      return;
    }

    try {
      final videoEnabled = resolvedArgument.isVideoCall;
      if (videoEnabled) {
        final cameraGranted = await _ensureCallPermission(
          permission: Permission.camera,
          deniedMessage:
              'ChatKuy membutuhkan akses kamera untuk panggilan video',
        );
        if (!cameraGranted) {
          await _closeCallForMissingPermission(
            'Izin kamera ditolak, panggilan ditutup',
          );
          return;
        }
      }

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': videoEnabled
            ? {
                'facingMode': 'user',
              }
            : false,
      });
      if (videoEnabled) {
        localRenderer.srcObject = _localStream;
        isLocalVideoEnabled = true;
        isVideoEnabled = true;
      }

      await Helper.setSpeakerphoneOn(isSpeakerOn);

      _peerConnection = await createPeerConnection(_configuration);
      _peerConnection?.onIceConnectionState = _handleIceState;
      _peerConnection?.onConnectionState =
          (state) => debugPrint('Call peer state: $state');

      for (final track in _localStream!.getTracks()) {
        await _peerConnection?.addTrack(track, _localStream!);
      }

      _peerConnection?.onIceCandidate = (candidate) {
        final callId = _callId;
        if (callId == null || candidate.candidate == null) return;

        callRepository.addCandidate(
          callId: callId,
          isCaller: resolvedArgument.isCaller,
          candidate: {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      };

      _peerConnection?.onTrack = (event) {
        debugPrint(
          'Call remote track: kind=${event.track.kind}, streams=${event.streams.length}',
        );
        if (event.track.kind == 'video') {
          _attachRemoteVideo(event);
        } else {
          _markRemoteAudioReceived();
        }
      };

      if (resolvedArgument.isCaller) {
        await _startOutgoingCall(resolvedArgument);
      } else {
        await _answerIncomingCall();
      }
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Start call media session failed',
        context: {
          'room_id': resolvedArgument.roomId,
          'current_uid': resolvedArgument.currentUid,
          'target_uid': resolvedArgument.targetUid,
          'is_caller': resolvedArgument.isCaller,
        },
      );
      _showMessage('Gagal memulai panggilan: $e');
      await endCall(updateRemote: true);
    }
  }

  Future<void> _startOutgoingCall(CallArgument argument) async {
    final callRef = await callRepository.createCall(
      roomId: argument.roomId,
      callerId: argument.currentUid,
      calleeId: argument.targetUid,
      callerName: argument.currentUserName ?? 'ChatKuy',
      calleeName: argument.targetName,
      callType: argument.isVideoCall ? 'video' : 'voice',
    );

    _callId = callRef.id;
    _listenCall();
    _listenRemoteCandidates();

    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': argument.isVideoCall,
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

  Future<CallArgument> _resolveCallType(CallArgument argument) async {
    final callId = argument.callId;
    if (argument.isVideoCall || callId == null) return argument;

    try {
      final snapshot = await callRepository.watchCall(callId).first;
      final data = snapshot.data();
      if (data?[CallField.type] == 'video') {
        return argument.copyWith(isVideoCall: true);
      }
    } catch (error, stackTrace) {
      AppErrorLogger.recordError(
        error,
        stackTrace,
        reason: 'Resolve incoming call type failed',
        context: {'call_id': callId},
        showBottomSheet: false,
      );
    }

    return argument;
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
    final status = data?[CallField.status];
    if (_isClosedCallStatus(status) || _isEnding || _isDisposed) {
      return;
    }

    final offer = data?[CallField.offer];
    if (offer is! Map) {
      _showMessage('Panggilan belum siap');
      _close();
      return;
    }

    final peerConnection = _peerConnection;
    if (peerConnection == null) return;

    await peerConnection.setRemoteDescription(
      RTCSessionDescription(
        offer['sdp'] as String?,
        offer['type'] as String?,
      ),
    );
    _remoteDescriptionSet = true;
    await _flushPendingRemoteCandidates();

    if (_isEnding || _isDisposed) return;

    final answer = await peerConnection.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': argument?.isVideoCall == true,
    });
    await peerConnection.setLocalDescription(answer);
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
              reason: 'Apply remote call answer failed',
              context: {'call_id': callId},
            );
          });
        }

        try {
          await _handleVideoUpgradeState(data);
        } catch (error, stackTrace) {
          AppErrorLogger.recordError(
            error,
            stackTrace,
            reason: 'Handle video upgrade state failed',
            context: {'call_id': callId},
          );
          _showMessage('Gagal menyambungkan video: $error');
        }
      },
      onError: (error, stackTrace) {
        AppErrorLogger.recordError(
          error,
          stackTrace,
          reason: 'Call stream failed',
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
        reason: 'Call candidate stream failed',
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
        reason: 'Add remote call candidate failed',
        context: {'call_id': _callId},
      );
      debugPrint('Call addCandidate failed: $e');
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
          reason: 'Flush pending call candidate failed',
          context: {'call_id': _callId},
        );
        debugPrint('Call flush candidate failed: $e');
      }
    }
  }

  Future<void> _handleVideoUpgradeState(
    Map<String, dynamic> data,
  ) async {
    final currentArgument = argument;
    final callId = _callId;
    if (currentArgument == null || callId == null || _peerConnection == null) {
      return;
    }

    final upgradeStatus = data[CallField.videoUpgradeStatus];
    final requestedBy = data[CallField.videoUpgradeRequestedBy];
    final requestedByMe = requestedBy == currentArgument.currentUid;

    if (upgradeStatus == VideoUpgradeStatus.requested) {
      if (requestedByMe) {
        isVideoUpgradePending = true;
        statusText = 'Menunggu persetujuan video...';
      } else if (!isVideoEnabled && !isIncomingVideoUpgradeRequest) {
        isIncomingVideoUpgradeRequest = true;
        isVideoUpgradePending = false;
      }
      return;
    }

    if (upgradeStatus == VideoUpgradeStatus.declined) {
      if (isVideoUpgradePending && requestedByMe) {
        _showMessage('${currentArgument.targetName} menolak panggilan video');
      }
      isVideoUpgradePending = false;
      isIncomingVideoUpgradeRequest = false;
      return;
    }

    if (upgradeStatus != VideoUpgradeStatus.accepted) return;

    isVideoUpgradePending = false;
    isIncomingVideoUpgradeRequest = false;

    if (requestedByMe) {
      await _sendVideoOfferIfNeeded(callId);
      await _applyVideoAnswerIfNeeded(data);
      return;
    }

    await _applyVideoOfferIfNeeded(data, callId);
  }

  Future<void> _sendVideoOfferIfNeeded(String callId) async {
    if (_videoOfferSent) return;

    await _enableLocalVideo();
    final peerConnection = _peerConnection;
    if (peerConnection == null) return;

    final offer = await peerConnection.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await peerConnection.setLocalDescription(offer);
    _videoOfferSent = true;
    await callRepository.setVideoOffer(
      callId: callId,
      offer: {
        'type': offer.type,
        'sdp': offer.sdp,
      },
    );
    statusText = 'Menyambungkan video...';
  }

  Future<void> _applyVideoOfferIfNeeded(
    Map<String, dynamic> data,
    String callId,
  ) async {
    if (_videoOfferApplied) return;

    final offer = data[CallField.videoOffer];
    if (offer is! Map) return;

    await _enableLocalVideo();
    final peerConnection = _peerConnection;
    if (peerConnection == null) return;

    await peerConnection.setRemoteDescription(
      RTCSessionDescription(
        offer['sdp'] as String?,
        offer['type'] as String?,
      ),
    );
    _videoOfferApplied = true;
    _remoteDescriptionSet = true;
    await _flushPendingRemoteCandidates();

    final answer = await peerConnection.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await peerConnection.setLocalDescription(answer);
    await callRepository.setVideoAnswer(
      callId: callId,
      answer: {
        'type': answer.type,
        'sdp': answer.sdp,
      },
    );
    isVideoEnabled = true;
    statusText = 'Video tersambung';
  }

  Future<void> _applyVideoAnswerIfNeeded(Map<String, dynamic> data) async {
    if (_videoAnswerApplied) return;

    final answer = data[CallField.videoAnswer];
    if (answer is! Map) return;

    final peerConnection = _peerConnection;
    if (peerConnection == null) return;

    await peerConnection.setRemoteDescription(
      RTCSessionDescription(
        answer['sdp'] as String?,
        answer['type'] as String?,
      ),
    );
    _videoAnswerApplied = true;
    _remoteDescriptionSet = true;
    await _flushPendingRemoteCandidates();
    isVideoEnabled = true;
    statusText = 'Video tersambung';
  }

  Future<void> _enableLocalVideo() async {
    final existingVideoTracks = _localStream?.getVideoTracks() ?? [];
    if (existingVideoTracks.isNotEmpty) {
      localRenderer.srcObject = _localStream;
      isLocalVideoEnabled = existingVideoTracks.any((track) => track.enabled);
      isVideoEnabled = true;
      return;
    }

    if (_localVideoStream != null) {
      isLocalVideoEnabled = true;
      isVideoEnabled = true;
      return;
    }

    final cameraGranted = await _ensureCallPermission(
      permission: Permission.camera,
      deniedMessage: 'ChatKuy membutuhkan akses kamera untuk panggilan video',
    );
    if (!cameraGranted) {
      throw Exception('ChatKuy membutuhkan akses kamera untuk panggilan video');
    }

    await _ensureVideoRenderersInitialized();
    _localVideoStream = await navigator.mediaDevices.getUserMedia({
      'audio': false,
      'video': {
        'facingMode': 'user',
      },
    });
    localRenderer.srcObject = _localVideoStream;

    final peerConnection = _peerConnection;
    if (peerConnection != null) {
      for (final track in _localVideoStream!.getVideoTracks()) {
        await peerConnection.addTrack(track, _localVideoStream!);
      }
    }

    isLocalVideoEnabled = true;
    isVideoEnabled = true;
  }

  Future<void> _ensureVideoRenderersInitialized() async {
    if (_videoRenderersInitialized) return;
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _videoRenderersInitialized = true;
  }

  @action
  void _attachRemoteVideo(RTCTrackEvent event) {
    if (event.streams.isEmpty) {
      debugPrint('Call remote video track has no stream yet');
      return;
    }

    remoteRenderer.srcObject = event.streams.first;
    hasRemoteVideo = true;
    isVideoEnabled = true;
    statusText = 'Video tersambung';
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
  Future<void> requestVideoUpgrade() async {
    final callId = _callId;
    final currentArgument = argument;
    if (callId == null || currentArgument == null || isIncomingRinging) return;

    if (!isCallActive) {
      _showMessage(AppTranslationKey.waitUntilCallConnected.tr);
      return;
    }

    if (isVideoEnabled) {
      await toggleCamera();
      return;
    }

    if (isVideoUpgradePending) {
      _showMessage(AppTranslationKey.videoRequestPending.tr);
      return;
    }

    isVideoUpgradePending = true;
    statusText = AppTranslationKey.requestingVideoPermission.tr;
    await callRepository.requestVideoUpgrade(
      callId: callId,
      requestedBy: currentArgument.currentUid,
    );
  }

  @action
  Future<void> acceptVideoUpgrade() async {
    final callId = _callId;
    if (callId == null) return;

    try {
      await _enableLocalVideo();
      isIncomingVideoUpgradeRequest = false;
      isVideoUpgradePending = false;
      await callRepository.respondVideoUpgrade(
        callId: callId,
        accepted: true,
      );
      _showMessage(AppTranslationKey.videoCallStarted.tr);
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Accept video upgrade failed',
        context: {'call_id': callId},
      );
      _showMessage('Gagal mengaktifkan kamera: $e');
      await callRepository.respondVideoUpgrade(
        callId: callId,
        accepted: false,
      );
    }
  }

  @action
  Future<void> declineVideoUpgrade() async {
    final callId = _callId;
    if (callId == null) return;

    isIncomingVideoUpgradeRequest = false;
    await callRepository.respondVideoUpgrade(
      callId: callId,
      accepted: false,
    );
  }

  @action
  Future<void> toggleCamera() async {
    final videoTracks = _localVideoStream?.getVideoTracks().isNotEmpty == true
        ? _localVideoStream!.getVideoTracks()
        : _localStream?.getVideoTracks() ?? [];
    if (videoTracks.isEmpty) return;

    final nextEnabled = !isLocalVideoEnabled;
    for (final track in videoTracks) {
      track.enabled = nextEnabled;
    }
    isLocalVideoEnabled = nextEnabled;
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
    debugPrint('Call ICE state: $state');

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

  Future<bool> _ensureCallPermission({
    required Permission permission,
    required String deniedMessage,
  }) async {
    final currentStatus = await permission.status;
    if (currentStatus.isGranted) return true;

    final requestedStatus = await permission.request();
    if (requestedStatus.isGranted) return true;

    _showMessage(deniedMessage);
    return false;
  }

  Future<void> _closeCallForMissingPermission(String message) async {
    if (_isEnding) return;
    _isEnding = true;
    _showMessage(message);

    final callId = _callId;
    if (callId != null) {
      await callRepository.declineCall(callId);
    }

    await _teardownCallResources(endCallKit: true);
    _close();
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

  bool _isClosedCallStatus(dynamic status) {
    return status == CallStatus.declined ||
        status == CallStatus.ended ||
        status == CallStatus.missed;
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
    _localVideoStream?.getTracks().forEach((track) => track.stop());
    await _localVideoStream?.dispose();
    _localVideoStream = null;
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    _videoRenderersInitialized = false;
    _pendingRemoteCandidates.clear();
    _addedCandidateIds.clear();

    final callId = _callId;
    if (endCallKit && callId != null) {
      await LocalNotificationService.finishCallKitCall(callId);
    }
  }

  @action
  void dispose() {
    unawaited(_teardownCallResources(endCallKit: false));
  }
}
