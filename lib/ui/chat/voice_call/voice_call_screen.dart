import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/helpers/call_lifecycle_helper.dart';
import 'package:chatkuy/core/navigation/initial_route_argument.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/chat/voice_call/voice_call_store.dart';
import 'package:chatkuy/ui/chat/voice_call/voice_call_argument.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  VoiceCallArgument? _argument;
  bool _closeAppOnEnd = false;
  bool _isClosing = false;
  final VoiceCallStore store = VoiceCallStore(
    callRepository: getIt<CallRepository>(),
  );

  @override
  void initState() {
    super.initState();
    _argument = Get.arguments as VoiceCallArgument? ?? InitialRouteArgument.takeVoiceCall();
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
    Get.snackbar('Telepon suara', message);
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => store.endCall(),
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
                      (argument?.targetName.isNotEmpty == true ? argument!.targetName[0] : '?').toUpperCase(),
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
                    store.hasRemoteAudio ? 'Audio tersambung' : store.statusText,
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
                  const Spacer(),
                  if (store.isIncomingRinging)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CallControlButton(
                          icon: Icons.call_end,
                          label: 'Tolak',
                          color: Colors.redAccent,
                          onTap: store.declineIncomingCall,
                        ),
                        _CallControlButton(
                          icon: Icons.call,
                          label: 'Terima',
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
                          icon: Icons.call_end,
                          label: 'Akhiri',
                          color: Colors.redAccent,
                          onTap: () => store.endCall(),
                        ),
                        _CallControlButton(
                          icon: store.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          label: 'Speaker',
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
