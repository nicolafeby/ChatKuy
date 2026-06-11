import 'dart:io';

import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:chatkuy/core/helpers/video_compress_helper.dart';
import 'package:chatkuy/core/helpers/video_player_helper.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class ChatAttachVideoArgument {
  const ChatAttachVideoArgument({required this.video, required this.store});

  final File video;
  final ChatRoomStore store;
}

class ChatAttachVideoScreen extends StatefulWidget {
  const ChatAttachVideoScreen({super.key});

  @override
  State<ChatAttachVideoScreen> createState() => _ChatAttachVideoScreenState();
}

class _ChatAttachVideoScreenState extends State<ChatAttachVideoScreen> {
  ChatAttachVideoArgument? argument;
  final ValueNotifier<VideoPlayerController?> _controller = ValueNotifier(null);
  final ValueNotifier<File?> _thumbnail = ValueNotifier(null);
  final ValueNotifier<bool> _isPreparingPlayer = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ChatAttachVideoArgument?;
    final video = argument?.video;
    if (video == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThumbnail(video);
      _preparePlayer(autoPlay: false);
    });
  }

  @override
  void dispose() {
    _controller.value?.removeListener(_handleControllerTick);
    _controller.value?.dispose();
    _controller.dispose();
    _thumbnail.dispose();
    _isPreparingPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = argument?.video;
    if (video == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: Center(child: _buildVideoPreview())),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(bottom: false, child: _buildHeaderButton()),
          ),
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom: 82.h + MediaQuery.viewInsetsOf(context).bottom,
            child: _buildVideoProgress(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _AttachCaptionBar(
              store: argument!.store,
              onSend: () => _sendVideo(video),
            ),
          ),
        ],
      ),
    );
  }

  void _sendVideo(File video) {
    _controller.value?.pause();
    argument!.store.sendVideoMessage(
      argument!.store.messageController.text.trim(),
      video,
    );
    argument!.store.messageController.clear();
    Get.back();
  }

  Widget _buildVideoPreview() {
    return ValueListenableBuilder<VideoPlayerController?>(
      valueListenable: _controller,
      builder: (context, controller, _) {
        if (controller == null || !controller.value.isInitialized) {
          return GestureDetector(
            onTap: () => _preparePlayer(autoPlay: true),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildPoster(),
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isPreparingPlayer,
                    builder: (context, isPreparingPlayer, _) {
                      if (isPreparingPlayer) {
                        return SizedBox(
                          width: 34.r,
                          height: 34.r,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        );
                      }

                      return Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 34.r,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: _togglePlay,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
              if (!controller.value.isPlaying)
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 34.r,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoProgress() {
    return ValueListenableBuilder<VideoPlayerController?>(
      valueListenable: _controller,
      builder: (context, controller, _) {
        if (controller == null || !controller.value.isInitialized) {
          return const SizedBox.shrink();
        }

        final position = controller.value.position;
        final duration = controller.value.duration;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white38,
                backgroundColor: Colors.white24,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPoster() {
    return ValueListenableBuilder<File?>(
      valueListenable: _thumbnail,
      builder: (context, thumbnail, _) {
        if (thumbnail == null) return _buildPosterFallback();

        return Image.file(
          thumbnail,
          fit: BoxFit.contain,
          width: 1.sw,
          errorBuilder: (context, error, stackTrace) => _buildPosterFallback(),
        );
      },
    );
  }

  Widget _buildPosterFallback() {
    return Container(
      width: 1.sw,
      height: 0.55.sh,
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam_outlined,
            color: Colors.white70,
            size: 52.r,
          ),
          10.verticalSpace,
          Text(
            'Video siap dikirim',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.45),
              foregroundColor: Colors.white,
            ),
            onPressed: Get.back,
            icon: Icon(Icons.close, size: 22.r),
          ),
          const Spacer(),
          ValueListenableBuilder<VideoPlayerController?>(
            valueListenable: _controller,
            builder: (context, controller, _) {
              final isPlaying = controller?.value.isPlaying == true;

              return IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                ),
                onPressed: controller?.value.isInitialized == true
                    ? _togglePlay
                    : () => _preparePlayer(autoPlay: true),
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 24.r,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _togglePlay() {
    final controller = _controller.value;
    if (controller == null || !controller.value.isInitialized) return;

    controller.value.isPlaying ? controller.pause() : controller.play();
    if (mounted) setState(() {});
  }

  Future<void> _loadThumbnail(File video) async {
    final thumbnail = await getChatVideoThumbnail(videoFile: video);
    if (!mounted || thumbnail == null) return;

    _thumbnail.value = thumbnail;
  }

  Future<void> _preparePlayer({required bool autoPlay}) async {
    final video = argument?.video;
    if (video == null || _isPreparingPlayer.value) return;

    final existingController = _controller.value;
    if (existingController != null && existingController.value.isInitialized) {
      if (autoPlay) existingController.play();
      if (mounted) setState(() {});
      return;
    }

    _isPreparingPlayer.value = true;

    final controller = await VideoPlayerHelper.initializeFile(
      file: video,
      reason: 'Prepare chat attachment video player failed',
    );

    if (!mounted) {
      await controller?.dispose();
      return;
    }

    if (controller != null) {
      controller.addListener(_handleControllerTick);
      if (autoPlay) await controller.play();
    }

    _controller.value = controller;
    _isPreparingPlayer.value = false;
  }

  void _handleControllerTick() {
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AttachCaptionBar extends StatelessWidget {
  const _AttachCaptionBar({
    required this.store,
    required this.onSend,
  });

  final ChatRoomStore store;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 22.h, 12.w, 8.h),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxHeight: 122.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: TextField(
                  controller: store.messageController,
                  onChanged: store.onTypingChanged,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: Colors.white, fontSize: 15.sp),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppTranslationKey.message.tr,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              ),
            ),
            10.horizontalSpace,
            SizedBox(
              width: 48.r,
              height: 48.r,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: onSend,
                icon: Icon(Icons.send, size: 22.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
