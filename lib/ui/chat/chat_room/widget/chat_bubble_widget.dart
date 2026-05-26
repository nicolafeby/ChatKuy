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
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

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
    this.searchQuery = '',
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
  final String searchQuery;

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
    final replyProgress = (_dragOffset / _replyTriggerOffset).clamp(0.0, 1.0).toDouble();
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
          mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                            color: AppColor.primaryColor.withValues(alpha: 0.14),
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
                    onLongPress: widget.onSelect == null && widget.onDelete == null ? null : _handleLongPress,
                    onHorizontalDragStart:
                        widget.onReply == null || widget.selectionMode ? null : _onHorizontalDragStart,
                    onHorizontalDragUpdate:
                        widget.onReply == null || widget.selectionMode ? null : _onHorizontalDragUpdate,
                    onHorizontalDragEnd: widget.onReply == null || widget.selectionMode ? null : _onHorizontalDragEnd,
                    onHorizontalDragCancel: widget.onReply == null || widget.selectionMode ? null : _resetDrag,
                    child: AnimatedContainer(
                      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(_dragOffset, 0, 0),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: _bubbleRadius(),
                        border: _isSearchMatch()
                            ? Border.all(
                                color: Colors.amber,
                                width: 1.5,
                              )
                            : null,
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
    final nextOffset = (_dragOffset + details.delta.dx).clamp(0.0, _maxDragOffset).toDouble();
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
    final shouldReply = _dragOffset >= _replyTriggerOffset || (details.primaryVelocity ?? 0) > 480;

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
    final hasImage = type == MessageType.image && (localImagePath != null || imageUrl != null);
    final videoUrl = widget.message.videoUrl;
    final localVideoPath = widget.message.localVideoPath;
    final playableLocalVideoPath = _existingFilePath(localVideoPath);
    final hasVideo = type == MessageType.video && (playableLocalVideoPath != null || videoUrl != null);
    final messageTextColor = widget.isMe ? Colors.white.withValues(alpha: isDarkMode ? 0.9 : 1) : colorScheme.onSurface;
    final metaTextColor = widget.isMe ? Colors.white.withValues(alpha: 0.68) : colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.message.replyToMessageId != null) ...[
          _buildReplyPreview(messageTextColor, metaTextColor),
          6.verticalSpace,
        ],
        if (type == MessageType.call) ...[
          _buildCallContent(messageTextColor, metaTextColor),
        ] else if (type == MessageType.file) ...[
          _buildFileContent(messageTextColor, metaTextColor),
        ] else if (type == MessageType.contact) ...[
          _buildContactContent(messageTextColor, metaTextColor),
        ] else if (hasImage) ...[
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
                replacement: const SizedBox.shrink(),
                child: _buildMessageText(
                  widget.message.text ?? '',
                  messageTextColor,
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
                replacement: const SizedBox.shrink(),
                child: _buildMessageText(
                  widget.message.text ?? '',
                  messageTextColor,
                ),
              ),
            ],
          )
        ] else ...[
          _buildMessageText(
            widget.message.text ?? '',
            messageTextColor,
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

  bool _isSearchMatch() {
    final query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return false;

    return (widget.message.text ?? '').toLowerCase().contains(query) ||
        (widget.message.replyToText ?? '').toLowerCase().contains(query) ||
        _messageTypeLabel(widget.message.type).toLowerCase().contains(query);
  }

  Widget _buildMessageText(String text, Color textColor) {
    return _buildHighlightedText(
      text: text,
      color: textColor,
      fontSize: 14.sp,
    );
  }

  Widget _buildHighlightedText({
    required String text,
    required Color color,
    required double fontSize,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
  }) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
    );
    final query = widget.searchQuery.trim();

    if (query.isEmpty || text.toLowerCase().contains(query.toLowerCase()) == false) {
      return Text(
        text,
        softWrap: true,
        textAlign: TextAlign.left,
        maxLines: maxLines,
        overflow: overflow,
        style: textStyle,
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    var start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            color: Colors.black,
            backgroundColor: Colors.amber,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + query.length;
    }

    return RichText(
      textAlign: TextAlign.left,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(
        style: textStyle,
        children: spans,
      ),
    );
  }

  String _messageTypeLabel(MessageType type) {
    if (type == MessageType.image) return 'Foto';
    if (type == MessageType.video) return 'Video';
    if (type == MessageType.call) return 'Panggilan';
    if (type == MessageType.file) return 'Dokumen';
    if (type == MessageType.contact) return 'Kontak';
    return 'Pesan';
  }

  Widget _buildFileContent(Color messageTextColor, Color metaTextColor) {
    final fileName = widget.message.fileName ?? 'Dokumen';
    final fileMeta = [
      if (widget.message.fileExtension?.isNotEmpty == true) widget.message.fileExtension,
      if (widget.message.fileSize != null) _formatBytes(widget.message.fileSize!),
    ].whereType<String>().join(' • ');

    return InkWell(
      onTap: _openFile,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.white.withValues(alpha: 0.16) : AppColor.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              size: 20.r,
              color: widget.isMe ? Colors.white : AppColor.primaryColor,
            ),
          ),
          8.horizontalSpace,
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: messageTextColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (fileMeta.isNotEmpty) ...[
                  2.verticalSpace,
                  Text(
                    fileMeta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: metaTextColor,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactContent(Color messageTextColor, Color metaTextColor) {
    final contactName = widget.message.contactName ?? 'Kontak';
    final contactPhone = widget.message.contactPhone ?? '';

    return InkWell(
      onTap: contactPhone.isEmpty ? null : () => launchUrl(Uri(scheme: 'tel', path: contactPhone)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.white.withValues(alpha: 0.16) : AppColor.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 20.r,
              color: widget.isMe ? Colors.white : AppColor.primaryColor,
            ),
          ),
          8.horizontalSpace,
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contactName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: messageTextColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (contactPhone.isNotEmpty) ...[
                  2.verticalSpace,
                  Text(
                    contactPhone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: metaTextColor,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallContent(Color messageTextColor, Color metaTextColor) {
    final isVideo = widget.message.callType == 'video';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
            color: widget.isMe ? Colors.white.withValues(alpha: 0.16) : AppColor.primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isVideo ? Icons.videocam_outlined : Icons.call_outlined,
            size: 18.r,
            color: widget.isMe ? Colors.white : AppColor.primaryColor,
          ),
        ),
        8.horizontalSpace,
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVideo ? 'Panggilan video' : 'Panggilan suara',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: messageTextColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              2.verticalSpace,
              Text(
                _callSubtitle(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: metaTextColor,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _callSubtitle() {
    final status = widget.message.callStatus;
    if (status == 'declined') return 'Ditolak';
    if (status == 'missed') return 'Tak terjawab';
    if (status == 'calling' || status == 'ringing') return 'Berlangsung';

    final seconds = widget.message.callDurationSeconds ?? 0;
    if (seconds <= 0) return 'Berakhir';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes <= 0) return '$remainingSeconds detik';
    return '$minutes menit ${remainingSeconds.toString().padLeft(2, '0')} detik';
  }

  Widget _buildReplyPreview(Color messageTextColor, Color metaTextColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.06),
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
                _buildHighlightedText(
                  text: _replyPreviewText(),
                  color: metaTextColor,
                  fontSize: 11.sp,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
    if (widget.message.replyToType == MessageType.file) return 'Dokumen';
    if (widget.message.replyToType == MessageType.contact) return 'Kontak';
    return 'Pesan';
  }

  String _replySenderName() {
    if (widget.message.replyToSenderId != null && widget.message.replyToSenderId == widget.currentUid) {
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

  Future<void> _openFile() async {
    final localFilePath = _existingFilePath(widget.message.localFilePath);
    if (localFilePath != null) {
      final result = await OpenFilex.open(localFilePath);
      if (result.type == ResultType.done) return;

      if (!mounted) return;
      Get.snackbar(
        'Chat',
        result.message.isEmpty ? 'File tidak bisa dibuka' : result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final uri = Uri.tryParse(widget.message.fileUrl ?? '');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
