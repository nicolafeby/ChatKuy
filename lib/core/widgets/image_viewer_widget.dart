import 'dart:io';

import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageViewerArgument {
  final String? imageUrl;
  final String? localImagePath;
  final String heroTag;

  const ImageViewerArgument({
    required this.imageUrl,
    this.localImagePath,
    String? heroTag,
  }) : heroTag = heroTag ?? imageUrl ?? AppStrings.dummyNetworkImage;
}

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  ImageViewerArgument? argument;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ImageViewerArgument?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: argument?.heroTag ?? AppStrings.dummyNetworkImage,
            child: InteractiveViewer(
              child: _buildImage(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final localImagePath = argument?.localImagePath;
    if (localImagePath != null && File(localImagePath).existsSync()) {
      return Image.file(
        File(localImagePath),
        fit: BoxFit.contain,
      );
    }

    return Image.network(
      argument?.imageUrl ?? AppStrings.dummyNetworkImage,
      fit: BoxFit.contain,
    );
  }
}
