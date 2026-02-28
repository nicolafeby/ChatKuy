import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageViewerArgument {
  final String imageUrl;

  const ImageViewerArgument({required this.imageUrl});
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
            tag: argument?.imageUrl ?? AppStrings.dummyNetworkImage,
            child: InteractiveViewer(
              child: Image.network(
                argument?.imageUrl ?? AppStrings.dummyNetworkImage,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
