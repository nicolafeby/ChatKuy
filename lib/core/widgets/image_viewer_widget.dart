import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/widgets/media_viewer_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageViewerArgument {
  final String? imageUrl;
  final String? localImagePath;
  final String heroTag;
  final List<MediaViewerItem> mediaItems;
  final int initialIndex;

  const ImageViewerArgument({
    required this.imageUrl,
    this.localImagePath,
    String? heroTag,
    this.mediaItems = const [],
    this.initialIndex = 0,
  }) : heroTag = heroTag ?? imageUrl ?? AppStrings.dummyNetworkImage;
}

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final argument = Get.arguments as ImageViewerArgument?;
    final fallbackItem = MediaViewerItem(
      heroTag: argument?.heroTag ?? AppStrings.dummyNetworkImage,
      imageUrl: argument?.imageUrl,
      localImagePath: argument?.localImagePath,
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
