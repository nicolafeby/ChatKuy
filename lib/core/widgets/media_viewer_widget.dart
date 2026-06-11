import 'dart:io';

import 'package:chatkuy/core/helpers/video_player_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class MediaViewerItem {
  const MediaViewerItem({
    required this.heroTag,
    this.imageUrl,
    this.localImagePath,
    this.videoUrl,
    this.localVideoPath,
  });

  final String heroTag;
  final String? imageUrl;
  final String? localImagePath;
  final String? videoUrl;
  final String? localVideoPath;

  bool get isVideo => videoUrl?.isNotEmpty == true || localVideoPath != null;
}

class MediaViewer extends StatefulWidget {
  const MediaViewer({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  final List<MediaViewerItem> items;
  final int initialIndex;

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.items.isEmpty ? 0 : widget.items.length - 1;
    _currentIndex = widget.initialIndex.clamp(0, maxIndex);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _showControls = true;
              });
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              if (item.isVideo) {
                return _MediaVideoPage(
                  item: item,
                  isActive: index == _currentIndex,
                  showControls: _showControls,
                  onToggleControls: _toggleControls,
                );
              }

              return _MediaImagePage(
                item: item,
                onToggleControls: _toggleControls,
                onZoomChanged: (isZoomed) {
                  setState(() => _showControls = !isZoomed);
                },
              );
            },
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            top: _showControls ? 0 : -104.h,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _MediaViewerHeader(
                currentIndex: _currentIndex,
                itemCount: widget.items.length,
                onClose: Get.back,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }
}

class _MediaViewerHeader extends StatelessWidget {
  const _MediaViewerHeader({
    required this.currentIndex,
    required this.itemCount,
    required this.onClose,
  });

  final int currentIndex;
  final int itemCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
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
            onPressed: onClose,
            icon: Icon(Icons.close, size: 22.r),
          ),
          const Spacer(),
          if (itemCount > 1)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Text(
                '${currentIndex + 1} / $itemCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaImagePage extends StatefulWidget {
  const _MediaImagePage({
    required this.item,
    required this.onToggleControls,
    required this.onZoomChanged,
  });

  final MediaViewerItem item;
  final VoidCallback onToggleControls;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_MediaImagePage> createState() => _MediaImagePageState();
}

class _MediaImagePageState extends State<_MediaImagePage> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggleControls,
      onDoubleTap: _toggleZoom,
      child: Hero(
        tag: widget.item.heroTag,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.8,
          maxScale: 4,
          child: Center(child: _buildImage()),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final localImagePath = widget.item.localImagePath;
    if (localImagePath != null && File(localImagePath).existsSync()) {
      return Image.file(
        File(localImagePath),
        fit: BoxFit.contain,
        width: 1.sw,
        errorBuilder: (context, error, stackTrace) => _buildErrorState(),
      );
    }

    return Image.network(
      widget.item.imageUrl ?? '',
      fit: BoxFit.contain,
      width: 1.sw,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorState(),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.broken_image_outlined,
          color: Colors.white70,
          size: 58.r,
        ),
        10.verticalSpace,
        Text(
          'Gambar tidak dapat dimuat',
          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
        ),
      ],
    );
  }

  void _toggleZoom() {
    final nextZoomed = !_isZoomed;
    _transformationController.value = nextZoomed
        ? (Matrix4.identity()..scaleByDouble(2.2, 2.2, 1, 1))
        : Matrix4.identity();
    _isZoomed = nextZoomed;
    widget.onZoomChanged(nextZoomed);
  }
}

class _MediaVideoPage extends StatefulWidget {
  const _MediaVideoPage({
    required this.item,
    required this.isActive,
    required this.showControls,
    required this.onToggleControls,
  });

  final MediaViewerItem item;
  final bool isActive;
  final bool showControls;
  final VoidCallback onToggleControls;

  @override
  State<_MediaVideoPage> createState() => _MediaVideoPageState();
}

class _MediaVideoPageState extends State<_MediaVideoPage> {
  final ValueNotifier<VideoPlayerController?> _controller = ValueNotifier(null);
  final ValueNotifier<bool> _hasError = ValueNotifier(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _MediaVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive) {
      _controller.value?.pause();
    } else if (!oldWidget.isActive) {
      _controller.value?.play();
    }
  }

  @override
  void dispose() {
    _controller.value?.removeListener(_handleControllerTick);
    _controller.value?.dispose();
    _controller.dispose();
    _hasError.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.item.heroTag,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: widget.onToggleControls,
            onDoubleTap: _togglePlay,
            child: _buildVideo(),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            left: 16.w,
            right: 16.w,
            bottom: widget.showControls ? 20.h : -64.h,
            child: SafeArea(top: false, child: _buildVideoProgress()),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    return ValueListenableBuilder<bool>(
      valueListenable: _hasError,
      builder: (context, hasError, _) {
        if (hasError) return _VideoErrorState(onRetry: _initController);

        return ValueListenableBuilder<bool>(
          valueListenable: _isLoading,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            return ValueListenableBuilder<VideoPlayerController?>(
              valueListenable: _controller,
              builder: (context, controller, _) {
                if (controller == null || !controller.value.isInitialized) {
                  return const SizedBox.shrink();
                }

                return Stack(
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
                        padding: EdgeInsets.all(16.r),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 40.r,
                        ),
                      ),
                  ],
                );
              },
            );
          },
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

        return Container(
          padding: EdgeInsets.fromLTRB(0, 18.h, 0, 10.h),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
          child: Column(
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
                    _formatDuration(controller.value.position),
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                  Text(
                    _formatDuration(controller.value.duration),
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _initController() async {
    final previousController = _controller.value;
    previousController?.removeListener(_handleControllerTick);
    await previousController?.dispose();
    _controller.value = null;
    _hasError.value = false;
    _isLoading.value = true;

    final localVideoPath = widget.item.localVideoPath;
    final localFile = localVideoPath == null ? null : File(localVideoPath);

    if (localFile != null && localFile.existsSync()) {
      final initialized = await _tryInitialize(
        VideoPlayerController.file(localFile),
      );
      if (initialized) return;
    }

    final videoUrl = widget.item.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final initialized = await _tryInitialize(
        VideoPlayerController.networkUrl(Uri.parse(videoUrl)),
      );
      if (!initialized && mounted) {
        _hasError.value = true;
        _isLoading.value = false;
      }
      return;
    }

    if (!mounted) return;
    _hasError.value = true;
    _isLoading.value = false;
  }

  Future<bool> _tryInitialize(VideoPlayerController controller) async {
    final initializedController = await VideoPlayerHelper.initializeController(
      controller: controller,
      reason: 'Initialize media viewer video failed',
      context: {
        'has_video_url': widget.item.videoUrl?.isNotEmpty == true,
        'has_local_video': widget.item.localVideoPath?.isNotEmpty == true,
      },
    );

    if (initializedController == null) return false;

    if (!mounted) {
      await initializedController.dispose();
      return false;
    }

    initializedController.addListener(_handleControllerTick);
    if (widget.isActive) await initializedController.play();
    _controller.value = initializedController;
    _hasError.value = false;
    _isLoading.value = false;

    return true;
  }

  void _togglePlay() {
    final controller = _controller.value;
    if (controller == null || !controller.value.isInitialized) return;

    controller.value.isPlaying ? controller.pause() : controller.play();
    if (mounted) setState(() {});
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

class _VideoErrorState extends StatelessWidget {
  const _VideoErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.videocam_off_outlined,
          color: Colors.white70,
          size: 64.r,
        ),
        12.verticalSpace,
        Text(
          'Video tidak dapat diputar',
          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
        ),
        14.verticalSpace,
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
          ),
          onPressed: onRetry,
          icon: Icon(Icons.refresh, size: 18.r),
          label: const Text('Coba lagi'),
        ),
      ],
    );
  }
}
