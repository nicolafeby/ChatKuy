import 'dart:collection';

import 'package:chatkuy/core/utils/extension/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final String? base64Image;
  final double size;
  const ProfileAvatarWidget({
    super.key,
    required this.base64Image,
    required this.size,
  });

  static final LinkedHashMap<String, MemoryImage> _imageCache =
      LinkedHashMap<String, MemoryImage>();
  static const int _maxCachedImages = 80;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _cachedImageProvider(base64Image);

    return SizedBox(
      height: size.r,
      width: size.r,
      child: CircleAvatar(
        radius: 24.r,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(Icons.person, size: (size / 2).r)
            : null,
      ),
    );
  }

  static MemoryImage? _cachedImageProvider(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return null;

    final cached = _imageCache.remove(base64Image);
    if (cached != null) {
      _imageCache[base64Image] = cached;
      return cached;
    }

    final image = MemoryImage(base64Image.base64GzipToBytes());
    _imageCache[base64Image] = image;

    if (_imageCache.length > _maxCachedImages) {
      _imageCache.remove(_imageCache.keys.first);
    }

    return image;
  }
}
