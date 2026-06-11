import 'dart:io';

import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/widgets/image_viewer_widget.dart';
import 'package:chatkuy/core/widgets/media_viewer_widget.dart';
import 'package:chatkuy/core/widgets/video_viewer_widget.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMediaGalleryArgument {
  const ChatMediaGalleryArgument({
    required this.roomName,
    required this.messages,
    this.roomId,
  });

  final String roomName;
  final List<ChatMessageModel> messages;
  final String? roomId;
}

class ChatMediaGalleryScreen extends StatefulWidget {
  const ChatMediaGalleryScreen({super.key});

  @override
  State<ChatMediaGalleryScreen> createState() => _ChatMediaGalleryScreenState();
}

class _ChatMediaGalleryScreenState extends State<ChatMediaGalleryScreen> {
  ChatMediaGalleryArgument? argument;
  final ChatRepository _chatRepository = getIt<ChatRepository>();

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ChatMediaGalleryArgument?;
  }

  @override
  Widget build(BuildContext context) {
    final roomId = argument?.roomId;
    if (roomId != null) {
      return StreamBuilder<List<ChatMessageModel>>(
        stream: _chatRepository.watchMessages(roomId: roomId),
        builder: (context, snapshot) {
          return _buildGallery(snapshot.data ?? argument?.messages ?? const []);
        },
      );
    }

    return _buildGallery(argument?.messages ?? const []);
  }

  Widget _buildGallery(List<ChatMessageModel> sourceMessages) {
    final messages = List<ChatMessageModel>.of(sourceMessages)
      ..sort((a, b) => b.createdAtClient.compareTo(a.createdAtClient));
    final mediaMessages = messages.where(_isMediaMessage).toList();
    final fileMessages = messages.where(_isFileMessage).toList();
    final linkItems = _buildLinkItems(messages);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppTranslationKey.mediaGallery.tr),
              Text(
                argument?.roomName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: AppTranslationKey.media.tr),
              Tab(text: AppTranslationKey.files.tr),
              Tab(text: AppTranslationKey.links.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MediaGrid(messages: mediaMessages),
            _FileList(messages: fileMessages),
            _LinkList(items: linkItems),
          ],
        ),
      ),
    );
  }

  bool _isMediaMessage(ChatMessageModel message) {
    if (message.type == MessageType.image) {
      return message.imageUrl?.isNotEmpty == true ||
          _existingFilePath(message.localImagePath) != null;
    }

    if (message.type == MessageType.video) {
      return message.videoUrl?.isNotEmpty == true ||
          _existingFilePath(message.localVideoPath) != null;
    }

    return false;
  }

  bool _isFileMessage(ChatMessageModel message) {
    return message.type == MessageType.file &&
        (message.fileUrl?.isNotEmpty == true ||
            _existingFilePath(message.localFilePath) != null);
  }

  List<_ChatLinkItem> _buildLinkItems(List<ChatMessageModel> messages) {
    return messages
        .expand(
          (message) => _extractLinks(message.text ?? '').map(
            (url) => _ChatLinkItem(url: url, message: message),
          ),
        )
        .toList();
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.messages});

  final List<ChatMessageModel> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _EmptyGalleryState(
        icon: Icons.collections_outlined,
        label: AppTranslationKey.noMediaYet.tr,
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(4.r),
      itemCount: messages.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4.r,
        crossAxisSpacing: 4.r,
      ),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isVideo = message.type == MessageType.video;
        final heroTag = _mediaHeroTag(message);

        return InkWell(
          onTap: () => isVideo ? _openVideo(message) : _openImage(message),
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPreview(message),
                  Positioned(
                    left: 6.w,
                    right: 6.w,
                    bottom: 6.h,
                    child: Row(
                      children: [
                        if (isVideo)
                          Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 24.r,
                          ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            message.createdAt.chatDayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreview(ChatMessageModel message) {
    if (message.type == MessageType.video) {
      return Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: Icon(
          Icons.videocam_outlined,
          color: Colors.white70,
          size: 34.r,
        ),
      );
    }

    final localImagePath = _existingFilePath(message.localImagePath);
    if (localImagePath != null) {
      return Image.file(
        File(localImagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _brokenPreview(),
      );
    }

    return Image.network(
      message.imageUrl ?? '',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _brokenPreview(),
    );
  }

  Widget _brokenPreview() {
    return Container(
      color: Colors.black12,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: Colors.grey,
        size: 30.r,
      ),
    );
  }

  void _openImage(ChatMessageModel message) {
    final mediaItems = _mediaViewerItems();

    Get.toNamed(
      AppRouteName.IMAGE_VIEWER_SCREEN,
      arguments: ImageViewerArgument(
        imageUrl: message.imageUrl,
        localImagePath: _existingFilePath(message.localImagePath),
        heroTag: _mediaHeroTag(message),
        mediaItems: mediaItems,
        initialIndex: _mediaInitialIndex(message, mediaItems),
      ),
    );
  }

  void _openVideo(ChatMessageModel message) {
    final mediaItems = _mediaViewerItems();

    Get.toNamed(
      AppRouteName.VIDEO_VIEWER_SCREEN,
      arguments: VideoViewerArgument(
        videoUrl: message.videoUrl,
        localVideoPath: _existingFilePath(message.localVideoPath),
        heroTag: _mediaHeroTag(message),
        mediaItems: mediaItems,
        initialIndex: _mediaInitialIndex(message, mediaItems),
      ),
    );
  }

  List<MediaViewerItem> _mediaViewerItems() {
    return messages
        .map(
          (message) => MediaViewerItem(
            heroTag: _mediaHeroTag(message),
            imageUrl: message.imageUrl,
            localImagePath: _existingFilePath(message.localImagePath),
            videoUrl: message.videoUrl,
            localVideoPath: _existingFilePath(message.localVideoPath),
          ),
        )
        .toList();
  }

  int _mediaInitialIndex(
    ChatMessageModel message,
    List<MediaViewerItem> mediaItems,
  ) {
    final index = mediaItems.indexWhere(
      (item) => item.heroTag == _mediaHeroTag(message),
    );
    return index < 0 ? 0 : index;
  }
}

class _FileList extends StatelessWidget {
  const _FileList({required this.messages});

  final List<ChatMessageModel> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _EmptyGalleryState(
        icon: Icons.insert_drive_file_outlined,
        label: AppTranslationKey.noFilesYet.tr,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: messages.length,
      separatorBuilder: (context, index) => Divider(height: 1.h),
      itemBuilder: (context, index) {
        final message = messages[index];
        final meta = [
          if (message.fileExtension?.isNotEmpty == true) message.fileExtension,
          if (message.fileSize != null) _formatBytes(message.fileSize!),
          message.createdAt.chatDayLabel,
        ].whereType<String>().join(' • ');

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColor.primaryColor.withValues(alpha: 0.12),
            foregroundColor: AppColor.primaryColor,
            child: const Icon(Icons.insert_drive_file_outlined),
          ),
          title: Text(
            message.fileName ?? AppTranslationKey.document.tr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _openFile(message),
        );
      },
    );
  }

  Future<void> _openFile(ChatMessageModel message) async {
    final localFilePath = _existingFilePath(message.localFilePath);
    if (localFilePath != null) {
      final result = await OpenFilex.open(localFilePath);
      if (result.type == ResultType.done) return;

      Get.snackbar(
        AppTranslationKey.chat.tr,
        result.message.isEmpty
            ? AppTranslationKey.fileOpenFailed.tr
            : result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final uri = Uri.tryParse(message.fileUrl ?? '');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _LinkList extends StatelessWidget {
  const _LinkList({required this.items});

  final List<_ChatLinkItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyGalleryState(
        icon: Icons.link,
        label: AppTranslationKey.noLinksYet.tr,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(height: 1.h),
      itemBuilder: (context, index) {
        final item = items[index];
        final uri = Uri.tryParse(item.url);
        final host = uri?.host.isNotEmpty == true ? uri!.host : item.url;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColor.primaryColor.withValues(alpha: 0.12),
            foregroundColor: AppColor.primaryColor,
            child: const Icon(Icons.link),
          ),
          title: Text(
            host,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${item.url}\n${item.message.createdAt.chatDayLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          trailing: IconButton(
            tooltip: AppTranslationKey.openLink.tr,
            onPressed: () => _openLink(item.url),
            icon: const Icon(Icons.open_in_new),
          ),
          onTap: () => _openLink(item.url),
        );
      },
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _EmptyGalleryState extends StatelessWidget {
  const _EmptyGalleryState({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: colorScheme.onSurfaceVariant,
            size: 42.r,
          ),
          10.verticalSpace,
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatLinkItem {
  const _ChatLinkItem({
    required this.url,
    required this.message,
  });

  final String url;
  final ChatMessageModel message;
}

List<String> _extractLinks(String text) {
  final matches = RegExp(
    r'((https?:\/\/|www\.)[^\s<>()]+)',
    caseSensitive: false,
  ).allMatches(text);

  return matches
      .map((match) => match.group(0) ?? '')
      .map((url) => url.replaceAll(RegExp(r'[.,!?;:]+$'), ''))
      .where((url) => url.isNotEmpty)
      .map((url) => url.startsWith('www.') ? 'https://$url' : url)
      .toSet()
      .toList();
}

String _mediaHeroTag(ChatMessageModel message) {
  return 'chat_media_gallery_${message.id}';
}

String? _existingFilePath(String? path) {
  if (path == null) return null;
  return File(path).existsSync() ? path : null;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';

  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';

  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';

  final gb = mb / 1024;
  return '${gb.toStringAsFixed(gb < 10 ? 1 : 0)} GB';
}
