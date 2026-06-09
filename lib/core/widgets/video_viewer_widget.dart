import 'dart:io';

import 'package:chatkuy/core/helpers/video_player_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoViewerArgument {
  const VideoViewerArgument({
    this.videoUrl,
    this.localVideoPath,
    required this.heroTag,
  });

  final String? videoUrl;
  final String? localVideoPath;
  final String heroTag;
}

class VideoViewerScreen extends StatefulWidget {
  const VideoViewerScreen({super.key});

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  VideoViewerArgument? argument;
  final ValueNotifier<VideoPlayerController?> _controller = ValueNotifier(null);
  final ValueNotifier<bool> _hasError = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as VideoViewerArgument?;
    _initController();
  }

  @override
  void dispose() {
    _controller.value?.dispose();
    _controller.dispose();
    _hasError.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = argument?.heroTag ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Hero(
                tag: heroTag,
                child: Material(
                  color: Colors.transparent,
                  child: _buildVideo(),
                ),
              ),
            ),
            Positioned(
              top: 16.h,
              left: 16.w,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  foregroundColor: Colors.white,
                ),
                onPressed: Get.back,
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    return ValueListenableBuilder<bool>(
      valueListenable: _hasError,
      builder: (context, hasError, _) {
        if (hasError) {
          return const Icon(
            Icons.videocam_off_outlined,
            color: Colors.white70,
            size: 64,
          );
        }

        return ValueListenableBuilder<VideoPlayerController?>(
          valueListenable: _controller,
          builder: (context, controller, _) {
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
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 36.r,
                      ),
                    ),
                  Positioned(
                    left: 16.w,
                    right: 16.w,
                    bottom: 20.h,
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.black26,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _initController() async {
    final localVideoPath = argument?.localVideoPath;
    final videoUrl = argument?.videoUrl;

    final localFile = localVideoPath == null ? null : File(localVideoPath);

    if (localFile != null && localFile.existsSync()) {
      final initialized = await _tryInitialize(
        VideoPlayerController.file(localFile),
      );

      if (initialized) return;
    }

    if (videoUrl != null && videoUrl.isNotEmpty) {
      final initialized = await _tryInitialize(
        VideoPlayerController.networkUrl(Uri.parse(videoUrl)),
      );
      if (!initialized && mounted) _hasError.value = true;
      return;
    }

    if (!mounted) return;
    _hasError.value = true;
  }

  Future<bool> _tryInitialize(VideoPlayerController controller) async {
    final initializedController = await VideoPlayerHelper.initializeController(
      controller: controller,
      reason: 'Initialize video viewer failed',
      context: {
        'has_video_url': argument?.videoUrl?.isNotEmpty == true,
        'has_local_video': argument?.localVideoPath?.isNotEmpty == true,
      },
    );

    if (initializedController == null) return false;

    if (!mounted) {
      await initializedController.dispose();
      return false;
    }

    _controller.value = initializedController;
    _hasError.value = false;

    return true;
  }

  void _togglePlay() {
    final controller = _controller.value;
    if (controller == null || !controller.value.isInitialized) return;

    controller.value.isPlaying ? controller.pause() : controller.play();
    if (mounted) setState(() {});
  }
}
