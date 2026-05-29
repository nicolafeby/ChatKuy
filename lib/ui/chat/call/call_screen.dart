import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/helpers/call_lifecycle_helper.dart';
import 'package:chatkuy/core/navigation/initial_route_argument.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/chat/call/call_store.dart';
import 'package:chatkuy/ui/chat/call/call_argument.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  CallArgument? _argument;
  bool _closeAppOnEnd = false;
  bool _isClosing = false;
  final CallStore store = CallStore(
    callRepository: getIt<CallRepository>(),
  );

  @override
  void initState() {
    super.initState();
    _argument =
        Get.arguments as CallArgument? ?? InitialRouteArgument.takeCall();
    final argument = _argument;
    if (argument == null) {
      _close();
      return;
    }

    _closeAppOnEnd = argument.closeAppOnEnd;
    store.init(
      argument: argument,
      onClose: _close,
      onMessage: _showMessage,
    );
  }

  void _close() {
    if (!mounted || _isClosing) return;
    _isClosing = true;

    if (_closeAppOnEnd) {
      if (Get.key.currentState != null) {
        Get.offAllNamed(AppRouteName.BASE_SCREEN);
      }

      Future<void>.delayed(
        const Duration(milliseconds: 250),
        CallLifecycleHelper.moveTaskToBackOrCloseApp,
      );
      return;
    }

    final navigator = Get.key.currentState;
    if (navigator?.canPop() == true) {
      Get.back();
      return;
    }

    Get.offAllNamed(AppRouteName.BASE_SCREEN);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    Get.snackbar(AppTranslationKey.call.tr, message);
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final argument = _argument;

    return Observer(
      builder: (_) {
        return Scaffold(
          backgroundColor: const Color(0xFF101820),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
              child: Column(
                children: [
                  _buildHeader(),
                  if (store.isVideoEnabled)
                    Expanded(child: _buildVideoStage(argument))
                  else ...[
                    const Spacer(),
                    _buildCallIdentity(argument),
                    const Spacer(),
                  ],
                  if (store.isIncomingVideoUpgradeRequest) ...[
                    _VideoUpgradePrompt(
                      callerName:
                          argument?.targetName ?? AppTranslationKey.friend.tr,
                      onAccept: store.acceptVideoUpgrade,
                      onDecline: store.declineVideoUpgrade,
                    ),
                    18.verticalSpace,
                  ],
                  if (store.isIncomingRinging)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CallControlButton(
                          icon: Icons.call_end,
                          label: AppTranslationKey.reject.tr,
                          color: Colors.redAccent,
                          onTap: store.declineIncomingCall,
                        ),
                        _CallControlButton(
                          icon: Icons.call,
                          label: AppTranslationKey.accept.tr,
                          color: Colors.green,
                          onTap: store.acceptIncomingCall,
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CallControlButton(
                          icon: store.isMuted ? Icons.mic_off : Icons.mic,
                          label: store.isMuted ? 'Unmute' : 'Mute',
                          onTap: store.toggleMute,
                        ),
                        _CallControlButton(
                          icon: store.isVideoEnabled
                              ? (store.isLocalVideoEnabled
                                  ? Icons.videocam
                                  : Icons.videocam_off)
                              : Icons.videocam,
                          label: store.isVideoEnabled
                              ? (store.isLocalVideoEnabled
                                  ? 'Kamera'
                                  : 'Kamera')
                              : AppTranslationKey.video.tr,
                          onTap: store.requestVideoUpgrade,
                        ),
                        _CallControlButton(
                          icon: Icons.call_end,
                          label: AppTranslationKey.end.tr,
                          color: Colors.redAccent,
                          onTap: () => store.endCall(),
                        ),
                        _CallControlButton(
                          icon: store.isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_down,
                          label: AppTranslationKey.speaker.tr,
                          onTap: store.toggleSpeaker,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => store.endCall(),
        icon: const Icon(Icons.keyboard_arrow_down),
        color: Colors.white,
        tooltip: AppTranslationKey.close.tr,
      ),
    );
  }

  Widget _buildCallIdentity(CallArgument? argument) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        _buildCallText(argument),
      ],
    );
  }

  Widget _buildCallText(CallArgument? argument) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          argument?.targetName ?? AppTranslationKey.voiceCall.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        8.verticalSpace,
        Text(
          store.isCallActive ? store.callDurationText : store.statusText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14.sp,
          ),
        ),
        if (store.isConnecting) ...[
          22.verticalSpace,
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ],
      ],
    );
  }

  Widget _buildVideoStage(CallArgument? argument) {
    return Padding(
      padding: EdgeInsets.only(top: 14.h, bottom: 24.h),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: ColoredBox(
                color: Colors.black,
                child: store.hasRemoteVideo
                    ? RTCVideoView(
                        store.remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : Center(child: _buildCallText(argument)),
              ),
            ),
          ),
          Positioned(
            right: 12.w,
            top: 12.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: SizedBox(
                width: 104.w,
                height: 148.h,
                child: ColoredBox(
                  color: const Color(0xFF1F2A35),
                  child: store.isLocalVideoEnabled
                      ? RTCVideoView(
                          store.localRenderer,
                          mirror: true,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : const Icon(
                          Icons.videocam_off,
                          color: Colors.white70,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoUpgradePrompt extends StatelessWidget {
  const _VideoUpgradePrompt({
    required this.callerName,
    required this.onAccept,
    required this.onDecline,
  });

  final String callerName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$callerName meminta beralih ke video',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  child: Text(AppTranslationKey.reject.tr),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppTranslationKey.accept.tr),
                ),
              ),
            ],
          ),
        ],
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
