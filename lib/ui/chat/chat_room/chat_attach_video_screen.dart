import 'dart:io';

import 'package:chatkuy/core/widgets/chat_field/chat_field.dart';
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
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ChatAttachVideoArgument?;
    final video = argument?.video;
    if (video == null) return;

    _controller = VideoPlayerController.file(video)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = argument?.video;
    if (video == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(child: _buildVideoPreview()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeaderButton(),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ChatField(
                store: argument!.store,
                disableAttachment: true,
                onSend: (text) {
                  argument!.store.sendVideoMessage(text, video);
                  argument!.store.messageController.clear();
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          if (!controller.value.isPlaying)
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
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
  }

  Widget _buildHeaderButton() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.65),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 20.r,
            ),
          ),
        ),
      ],
    ).paddingAll(20.r);
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }
}
