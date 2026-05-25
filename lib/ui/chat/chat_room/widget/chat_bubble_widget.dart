import 'dart:io';

import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/image_viewer_widget.dart';
import 'package:chatkuy/core/widgets/video_viewer_widget.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum UiMessageStatus {
  sent,
  delivered,
  read,
}

class ChatBubbleWidget extends StatefulWidget {
  const ChatBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.onRetry,
    this.uploadProgress,
    this.isFirstInGroup = true,
    this.isSameGroup = false,
    this.onReply,
    this.onDelete,
    this.onSelect,
    this.selectionMode = false,
    this.isSelected = false,
    this.currentUid,
    this.targetName,
  });

  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onRetry;
  final int? uploadProgress;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;
  final bool selectionMode;
  final bool isSelected;
  final String? currentUid;
  final String? targetName;

  final bool isFirstInGroup;
  final bool isSameGroup;

  @override
  State<ChatBubbleWidget> createState() => _ChatBubbleWidgetState();
}

class _ChatBubbleWidgetState extends State<ChatBubbleWidget> with BaseLayout {
  static const double _maxDragOffset = 72;
  static const double _replyTriggerOffset = 46;

  double _dragOffset = 0;
  bool _isDragging = false;
  bool _isReplyArmed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = colorSchemeOf(context);
    final isDarkMode = isDarkModeOf(context);
    final bubbleColor = widget.isMe
        ? AppColor.primaryColor.withValues(alpha: isDarkMode ? 0.7 : 0.8)
        : isDarkMode
            ? const Color(0xFF18232C)
            : Colors.grey.shade200;
    final replyProgress =
        (_dragOffset / _replyTriggerOffset).clamp(0.0, 1.0).toDouble();
    final selectedRowColor = AppColor.primaryColor.withValues(
      alpha: isDarkMode ? 0.22 : 0.12,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      color: widget.isSelected ? selectedRowColor : Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(
          top: widget.isSameGroup ? 1.5.h : 8.h,
          bottom: widget.isSelected ? 1.5.h : 0,
        ),
        child: Row(
          mainAxisAlignment:
              widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 12.w,
                    child: Opacity(
                      opacity: replyProgress,
                      child: Transform.scale(
                        scale: 0.82 + (replyProgress * 0.18),
                        child: Container(
                          width: 32.r,
                          height: 32.r,
                          decoration: BoxDecoration(
                            color:
                                AppColor.primaryColor.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.reply,
                            size: 18.r,
                            color: AppColor.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.selectionMode
                        ? widget.onSelect
                        : widget.message.status == MessageStatus.failed
                            ? widget.onRetry
                            : null,
                    onLongPress:
                        widget.onSelect == null && widget.onDelete == null
                            ? null
                            : _handleLongPress,
                    onHorizontalDragStart:
                        widget.onReply == null || widget.selectionMode
                            ? null
                            : _onHorizontalDragStart,
                    onHorizontalDragUpdate:
                        widget.onReply == null || widget.selectionMode
                            ? null
                            : _onHorizontalDragUpdate,
                    onHorizontalDragEnd:
                        widget.onReply == null || widget.selectionMode
                            ? null
                            : _onHorizontalDragEnd,
                    onHorizontalDragCancel:
                        widget.onReply == null || widget.selectionMode
                            ? null
                            : _resetDrag,
                    child: AnimatedContainer(
                      duration: _isDragging
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(_dragOffset, 0, 0),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: _bubbleRadius(),
                      ),
                      child: _buildContent(colorScheme, isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLongPress() {
    HapticFeedback.selectionClick();

    if (widget.onSelect != null) {
      widget.onSelect?.call();
      return;
    }

    _showMessageActions();
  }

  void _showMessageActions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onReply != null)
                ListTile(
                  leading: Icon(
                    Icons.reply,
                    color: colorScheme.onSurface,
                  ),
                  title: const Text('Balas'),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onReply?.call();
                  },
                ),
              if (widget.onDelete != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text('Hapus untuk saya'),
                  textColor: Colors.redAccent,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onDelete?.call();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _isReplyArmed = false;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final nextOffset =
        (_dragOffset + details.delta.dx).clamp(0.0, _maxDragOffset).toDouble();
    final nextIsReplyArmed = nextOffset >= _replyTriggerOffset;

    if (nextIsReplyArmed && !_isReplyArmed) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _dragOffset = nextOffset;
      _isReplyArmed = nextIsReplyArmed;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final shouldReply = _dragOffset >= _replyTriggerOffset ||
        (details.primaryVelocity ?? 0) > 480;

    if (shouldReply) {
      widget.onReply?.call();
    }

    _resetDrag();
  }

  void _resetDrag() {
    if (!mounted) return;

    setState(() {
      _isDragging = false;
      _isReplyArmed = false;
      _dragOffset = 0;
    });
  }

  BorderRadius _bubbleRadius() {
    final r = Radius.circular(8.r);

    return BorderRadius.only(
      topLeft: widget.isMe ? r : (widget.isSameGroup ? r : Radius.zero),
      topRight: widget.isMe ? (widget.isSameGroup ? r : Radius.zero) : r,
      bottomLeft: r,
      bottomRight: r,
    );
  }

  Widget _buildContent(ColorScheme colorScheme, bool isDarkMode) {
    final type = widget.message.type;
    final imageUrl = widget.message.imageUrl;
    final localImagePath = widget.message.localImagePath;
    final hasImage = type == MessageType.image &&
        (localImagePath != null || imageUrl != null);
    final videoUrl = widget.message.videoUrl;
    final localVideoPath = widget.message.localVideoPath;
    final playableLocalVideoPath = _existingFilePath(localVideoPath);
    final hasVideo = type == MessageType.video &&
        (playableLocalVideoPath != null || videoUrl != null);
    final messageTextColor = widget.isMe
        ? Colors.white.withValues(alpha: isDarkMode ? 0.9 : 1)
        : colorScheme.onSurface;
    final metaTextColor = widget.isMe
        ? Colors.white.withValues(alpha: 0.68)
        : colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.message.replyToMessageId != null) ...[
          _buildReplyPreview(messageTextColor, metaTextColor),
          6.verticalSpace,
        ],
        if (hasImage) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: imageUrl == null
                    ? null
                    : () => Get.toNamed(
                          AppRouteName.IMAGE_VIEWER_SCREEN,
                          arguments: ImageViewerArgument(imageUrl: imageUrl),
                        ),
                child: Hero(
                  tag: imageUrl ?? widget.message.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: _buildImagePreview(
                      imageUrl: imageUrl,
                      localImagePath: localImagePath,
                    ),
                  ),
                ),
              ),
              4.verticalSpace,
              Visibility(
                visible: widget.message.text?.isNotEmpty == true,
                child: Text(
                  widget.message.text ?? '',
                  softWrap: true,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: messageTextColor,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          )
        ] else if (hasVideo) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: InkWell(
                  onTap: () => _openVideoViewer(
                    videoUrl: videoUrl,
                    localVideoPath: playableLocalVideoPath,
                  ),
                  child: Hero(
                    tag: _videoHeroTag(videoUrl, playableLocalVideoPath),
                    child: _buildVideoPreview(
                      videoUrl: videoUrl,
                      localVideoPath: playableLocalVideoPath,
                    ),
                  ),
                ),
              ),
              4.verticalSpace,
              Visibility(
                visible: widget.message.text?.isNotEmpty == true,
                child: Text(
                  widget.message.text ?? '',
                  softWrap: true,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: messageTextColor,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          )
        ] else ...[
          Text(
            widget.message.text ?? '',
            softWrap: true,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: messageTextColor,
              fontSize: 14.sp,
            ),
          ),
        ],
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6.w,
          children: [
            Text(
              widget.message.createdAt.hhmm,
              style: TextStyle(
                color: metaTextColor,
                fontSize: 10.sp,
              ),
            ),
            if (widget.isMe) _buildStatusIcon(),
          ],
        ),
      ],
    );
  }

  Widget _buildReplyPreview(Color messageTextColor, Color metaTextColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3.w,
            height: 34.h,
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.white70 : AppColor.primaryColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          6.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replySenderName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: messageTextColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                2.verticalSpace,
                Text(
                  _replyPreviewText(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: metaTextColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _replyPreviewText() {
    final text = widget.message.replyToText?.trim();
    if (text != null && text.isNotEmpty) return text;
    if (widget.message.replyToType == MessageType.image) return 'Foto';
    if (widget.message.replyToType == MessageType.video) return 'Video';
    return 'Pesan';
  }

  String _replySenderName() {
    if (widget.message.replyToSenderId != null &&
        widget.message.replyToSenderId == widget.currentUid) {
      return 'Anda';
    }

    return widget.targetName ?? widget.message.replyToSenderName ?? 'Kontak';
  }

  Widget _buildImagePreview({
    required String? imageUrl,
    required String? localImagePath,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (localImagePath != null)
          Image.file(
            File(localImagePath),
            height: 200.h,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildBrokenImage(),
          )
        else if (imageUrl != null)
          Image.network(
            height: 200.h,
            width: double.infinity,
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildImageLoading();
            },
            errorBuilder: (context, error, stackTrace) => _buildBrokenImage(),
          )
        else
          _buildBrokenImage(),
        if (widget.message.status == MessageStatus.pending)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: _buildUploadProgress(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPreview({
    required String? videoUrl,
    required String? localVideoPath,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 200.h,
          width: double.infinity,
          color: Colors.black87,
          alignment: Alignment.center,
          child: Icon(
            Icons.play_circle_fill,
            size: 58.r,
            color: Colors.white,
          ),
        ),
        Positioned(
          left: 10.w,
          bottom: 10.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_outlined,
                  size: 14.r,
                  color: Colors.white,
                ),
                4.horizontalSpace,
                Text(
                  'Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.message.status == MessageStatus.pending)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black38,
              child: Center(
                child: _buildUploadProgress(),
              ),
            ),
          ),
      ],
    );
  }

  void _openVideoViewer({
    required String? videoUrl,
    required String? localVideoPath,
  }) {
    if (videoUrl == null && localVideoPath == null) return;

    Get.toNamed(
      AppRouteName.VIDEO_VIEWER_SCREEN,
      arguments: VideoViewerArgument(
        videoUrl: videoUrl,
        localVideoPath: localVideoPath,
        heroTag: _videoHeroTag(videoUrl, localVideoPath),
      ),
    );
  }

  String _videoHeroTag(String? videoUrl, String? localVideoPath) {
    return videoUrl ?? localVideoPath ?? widget.message.id;
  }

  String? _existingFilePath(String? path) {
    if (path == null) return null;
    return File(path).existsSync() ? path : null;
  }

  Widget _buildUploadProgress() {
    final progress = widget.uploadProgress?.clamp(0, 100);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 42.r,
          height: 42.r,
          child: CircularProgressIndicator(
            value: progress == null ? null : progress / 100,
            color: Colors.white,
            backgroundColor: Colors.white24,
            strokeWidth: 3,
          ),
        ),
        if (progress != null) ...[
          8.verticalSpace,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              '$progress%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageLoading() {
    return Container(
      height: 200.h,
      width: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildBrokenImage() {
    return Container(
      height: 200.h,
      width: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (widget.message.status == MessageStatus.failed) {
      return Icon(
        Icons.error,
        size: 12.sp,
        color: Colors.redAccent,
      );
    }

    if (widget.message.status == MessageStatus.pending) {
      return Icon(
        Icons.access_time,
        size: 12.sp,
        color: Colors.white70,
      );
    }

    final uiStatus = _resolveUiStatus();

    switch (uiStatus) {
      case UiMessageStatus.sent:
        return Icon(
          Icons.check,
          size: 12.sp,
          color: Colors.white70,
        );

      case UiMessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 12.sp,
          color: Colors.white70,
        );

      case UiMessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 12.sp,
          color: Colors.yellowAccent,
        );
    }
  }

  UiMessageStatus _resolveUiStatus() {
    if (widget.message.deliveredTo.isEmpty) {
      return UiMessageStatus.sent;
    }

    if (widget.message.readBy.isEmpty) {
      return UiMessageStatus.delivered;
    }

    return UiMessageStatus.read;
  }
}
