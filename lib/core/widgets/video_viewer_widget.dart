import 'package:chatkuy/core/widgets/media_viewer_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoViewerArgument {
  const VideoViewerArgument({
    this.videoUrl,
    this.localVideoPath,
    required this.heroTag,
    this.mediaItems = const [],
    this.initialIndex = 0,
  });

  final String? videoUrl;
  final String? localVideoPath;
  final String heroTag;
  final List<MediaViewerItem> mediaItems;
  final int initialIndex;
}

class VideoViewerScreen extends StatelessWidget {
  const VideoViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final argument = Get.arguments as VideoViewerArgument?;
    final fallbackItem = MediaViewerItem(
      heroTag: argument?.heroTag ?? '',
      videoUrl: argument?.videoUrl,
      localVideoPath: argument?.localVideoPath,
    );
    final items = argument?.mediaItems.isNotEmpty == true
        ? argument!.mediaItems
        : [fallbackItem];

    return MediaViewer(
      items: items,
      initialIndex: argument?.initialIndex ?? 0,
    );
  }
}
