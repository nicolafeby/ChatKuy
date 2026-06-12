import 'dart:async';
import 'dart:io';

import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/image_viewer_widget.dart';
import 'package:chatkuy/core/widgets/media_viewer_widget.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/core/widgets/video_viewer_widget.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:audioplayers/audioplayers.dart';
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

class _TextMatch {
  const _TextMatch(this.start, this.end);

  final int start;
  final int end;
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
    this.onReplyPreviewTap,
    this.onDelete,
    this.onSelect,
    this.onReact,
    this.selectionMode = false,
    this.isSelected = false,
    this.isJumpHighlighted = false,
    this.currentUid,
    this.targetName,
    this.showSenderInfo = false,
    this.senderUser,
    this.senderName,
    this.senderPhotoUrl,
    this.onSenderAvatarTap,
    this.searchQuery = '',
    this.mediaMessages = const [],
  });

  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onRetry;
  final int? uploadProgress;
  final VoidCallback? onReply;
  final VoidCallback? onReplyPreviewTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;
  final ValueChanged<String>? onReact;
  final bool selectionMode;
  final bool isSelected;
  final bool isJumpHighlighted;
  final String? currentUid;
  final String? targetName;
  final bool showSenderInfo;
  final UserModel? senderUser;
  final String? senderName;
  final String? senderPhotoUrl;
  final VoidCallback? onSenderAvatarTap;
  final String searchQuery;
  final List<ChatMessageModel> mediaMessages;

  final bool isFirstInGroup;
  final bool isSameGroup;

  @override
  State<ChatBubbleWidget> createState() => _ChatBubbleWidgetState();
}

class _ChatBubbleWidgetState extends State<ChatBubbleWidget> with BaseLayout {
  static const double _maxDragOffset = 72;
  static const double _replyTriggerOffset = 46;
  static const List<String> _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  AudioPlayer? _audioPlayer;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  double _dragOffset = 0;
  bool _isDragging = false;
  bool _isReplyArmed = false;
  bool _isAudioPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void didUpdateWidget(covariant ChatBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id == widget.message.id) return;
    _audioPlayer?.stop();
    _audioPosition = Duration.zero;
    _audioDuration = Duration.zero;
    _isAudioPlaying = false;
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  AudioPlayer _ensureAudioPlayer() {
    final existingPlayer = _audioPlayer;
    if (existingPlayer != null) return existingPlayer;

    final player = AudioPlayer();
    _audioPlayer = player;

    _playerStateSubscription = player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = state == PlayerState.playing;
      });
    });
    _positionSubscription = player.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() {
        _audioPosition = position;
      });
    });
    _durationSubscription = player.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        _audioDuration = duration;
      });
    });
    _playerCompleteSubscription = player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = false;
        _audioPosition = Duration.zero;
      });
    });

    return player;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = colorSchemeOf(context);
    final isDarkMode = isDarkModeOf(context);
    final bubbleColor = widget.isMe
        ? (isDarkMode ? const Color(0xFF005C4B) : AppColor.outgoingBubble)
        : isDarkMode
            ? const Color(0xFF202C33)
            : AppColor.incomingBubble;
    final replyProgress = (_dragOffset / _replyTriggerOffset).clamp(0.0, 1.0).toDouble();
    final selectedRowColor = AppColor.primaryColor.withValues(
      alpha: isDarkMode ? 0.22 : 0.12,
    );
    final highlightBorderColor = widget.isJumpHighlighted ? AppColor.primaryColor : Colors.amber;
    final shouldHighlightBubble = widget.isJumpHighlighted || _isSearchMatch() || _isMentionedCurrentUser();
    final showSenderAvatar = widget.showSenderInfo && widget.isFirstInGroup;
    final hasReactions = widget.message.reactions.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      color: widget.isSelected ? selectedRowColor : Colors.transparent,
      child: GestureDetector(
        behavior: widget.selectionMode ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
        onTap: widget.selectionMode ? widget.onSelect : null,
        child: Padding(
          padding: EdgeInsets.only(
            left: 10.w,
            right: 10.w,
            top: widget.isSameGroup ? 1.5.h : 8.h,
            bottom: widget.isSelected ? 1.5.h : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (widget.showSenderInfo) ...[
                SizedBox(
                  width: 32.r,
                  child: showSenderAvatar
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.selectionMode ? widget.onSelect : widget.onSenderAvatarTap,
                          child: ProfileAvatarWidget(
                            base64Image: widget.senderUser?.photoUrl ?? widget.senderPhotoUrl,
                            size: 28,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                4.horizontalSpace,
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * (widget.showSenderInfo ? 0.68 : 0.8),
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
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: hasReactions ? 10.h : 0,
                      ),
                      child: GestureDetector(
                        onTap: widget.selectionMode
                            ? widget.onSelect
                            : widget.message.status == MessageStatus.failed
                                ? widget.onRetry
                                : null,
                        onLongPressStart:
                            widget.onSelect == null && widget.onReact == null ? null : _handleLongPressStart,
                        onHorizontalDragStart:
                            widget.onReply == null || widget.selectionMode ? null : _onHorizontalDragStart,
                        onHorizontalDragUpdate:
                            widget.onReply == null || widget.selectionMode ? null : _onHorizontalDragUpdate,
                        onHorizontalDragEnd:
                            widget.onReply == null || widget.selectionMode ? null : _onHorizontalDragEnd,
                        onHorizontalDragCancel: widget.onReply == null || widget.selectionMode ? null : _resetDrag,
                        child: AnimatedContainer(
                          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          transform: Matrix4.translationValues(_dragOffset, 0, 0),
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: _bubbleRadius(),
                            border: shouldHighlightBubble
                                ? Border.all(
                                    color: _isMentionedCurrentUser() ? AppColor.primaryColor : highlightBorderColor,
                                    width: widget.isJumpHighlighted ? 2 : 1.5,
                                  )
                                : null,
                          ),
                          child: _buildContent(colorScheme, isDarkMode),
                        ),
                      ),
                    ),
                    if (hasReactions)
                      Positioned(
                        right: widget.isMe ? -2.w : null,
                        left: widget.isMe ? null : -2.w,
                        bottom: 0,
                        child: _buildReactionSummary(isDarkMode),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLongPressStart(LongPressStartDetails details) async {
    HapticFeedback.selectionClick();

    if (!widget.isSelected && widget.onSelect != null) {
      widget.onSelect?.call();
    }

    if (widget.onReact == null) return;

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    _showReactionMenu(details.globalPosition);
  }

  Future<void> _showReactionMenu(Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;

    final size = overlay.size;
    final menuWidth = 328.w.clamp(240.0, size.width - 24.w);
    final left = (globalPosition.dx - (menuWidth / 2)).clamp(
      12.0,
      size.width - menuWidth - 12.w,
    );
    final top = (globalPosition.dy - 68.h).clamp(
      MediaQuery.of(context).padding.top + 8.h,
      size.height - 72.h,
    );

    final selectedReaction = await showGeneralDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'Dismiss reactions',
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (routeContext, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: Material(
                type: MaterialType.transparency,
                child: _buildReactionPicker(routeContext),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );

    if (selectedReaction == null || !mounted) return;
    widget.onReact?.call(selectedReaction);
  }

  Widget _buildReactionPicker(BuildContext routeContext) {
    final currentReaction = widget.currentUid == null ? null : widget.message.reactions[widget.currentUid];
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = isDarkModeOf(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2C33) : colorScheme.surface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.28 : 0.16),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _quickReactions.map((emoji) {
          final isSelected = currentReaction == emoji;

          return InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Navigator.of(routeContext).pop(emoji);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 44.r,
              height: 44.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.primaryColor.withValues(alpha: 0.16)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: AppColor.primaryColor, width: 1.2) : null,
              ),
              child: Text(
                emoji,
                style: TextStyle(fontSize: 22.sp),
              ),
            ),
          );
        }).toList(),
      ),
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
    final r = Radius.circular(7.5.r);
    final tight = Radius.circular(2.r);

    return BorderRadius.only(
      topLeft: widget.isMe ? r : (widget.isSameGroup ? r : tight),
      topRight: widget.isMe ? (widget.isSameGroup ? r : tight) : r,
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
    final audioUrl = widget.message.audioUrl;
    final localAudioPath = _existingFilePath(widget.message.localAudioPath);
    final hasAudio = type == MessageType.audio && (localAudioPath != null || audioUrl != null);
    final messageTextColor = widget.isMe
        ? (isDarkMode ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF111B21))
        : colorScheme.onSurface;
    final metaTextColor =
        widget.isMe ? (isDarkMode ? Colors.white60 : const Color(0xFF667781)) : colorScheme.onSurfaceVariant;
    final isTextMessage = type != MessageType.call &&
        type != MessageType.file &&
        type != MessageType.contact &&
        !hasAudio &&
        !hasImage &&
        !hasVideo;

    final hasReply = widget.message.replyToMessageId != null;
    final content = Column(
      crossAxisAlignment: _contentCrossAxisAlignment(hasReply),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_shouldShowSenderName()) ...[
          _buildSenderName(),
          4.verticalSpace,
        ],
        if (hasReply) ...[
          _buildReplyPreview(messageTextColor, metaTextColor),
          6.verticalSpace,
        ],
        if (type == MessageType.call) ...[
          _buildCallContent(messageTextColor, metaTextColor),
        ] else if (type == MessageType.file) ...[
          _buildFileContent(messageTextColor, metaTextColor),
        ] else if (type == MessageType.contact) ...[
          _buildContactContent(messageTextColor, metaTextColor),
        ] else if (hasAudio) ...[
          _buildAudioContent(
            messageTextColor,
            metaTextColor,
            localAudioPath: localAudioPath,
            audioUrl: audioUrl,
          ),
        ] else if (hasImage) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: (imageUrl == null && localImagePath == null) ? null : _openImageViewer,
                child: Hero(
                  tag: _mediaHeroTag(widget.message),
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
        ] else if (isTextMessage) ...[
          _buildTextContent(
            widget.message.text ?? '',
            messageTextColor,
            metaTextColor,
          ),
        ] else ...[
          _buildMessageText(
            widget.message.text ?? '',
            messageTextColor,
          ),
        ],
        if (!isTextMessage) _buildMessageMeta(metaTextColor),
      ],
    );

    if (hasReply) {
      return IntrinsicWidth(child: content);
    }

    return content;
  }

  CrossAxisAlignment _contentCrossAxisAlignment(bool hasReply) {
    if (_shouldShowSenderName()) return CrossAxisAlignment.start;
    if (hasReply) return CrossAxisAlignment.stretch;
    return CrossAxisAlignment.end;
  }

  bool _shouldShowSenderName() {
    return widget.showSenderInfo && widget.isFirstInGroup;
  }

  Widget _buildSenderName() {
    final resolvedName = widget.senderName?.trim() ?? '';
    final style = TextStyle(
      color: AppColor.primaryColor,
      fontSize: 12.sp,
      fontWeight: FontWeight.w700,
    );

    return Opacity(
      opacity: resolvedName.isEmpty ? 0 : 1,
      child: Text(
        resolvedName.isEmpty ? 'Member' : resolvedName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  Widget _buildTextContent(
    String text,
    Color messageTextColor,
    Color metaTextColor,
  ) {
    if (_shouldShowInlineMeta(text)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildMessageText(text, messageTextColor),
          8.horizontalSpace,
          _buildMessageMeta(metaTextColor),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMessageText(text, messageTextColor),
        _buildMessageMeta(metaTextColor),
      ],
    );
  }

  bool _shouldShowInlineMeta(String text) {
    if (text.trim().isEmpty || text.contains('\n')) return false;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 14.sp),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    final maxContentWidth = (MediaQuery.of(context).size.width * 0.8) - 24.w;
    final metaWidth = _messageMetaEstimatedWidth();

    return textPainter.width + 8.w + metaWidth <= maxContentWidth;
  }

  double _messageMetaEstimatedWidth() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.message.createdAt.hhmm,
        style: TextStyle(fontSize: 10.sp),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    return textPainter.width + (widget.isMe ? 6.w + 12.sp : 0);
  }

  Widget _buildMessageMeta(Color metaTextColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.message.createdAt.hhmm,
          style: TextStyle(
            color: metaTextColor,
            fontSize: 10.sp,
          ),
        ),
        if (widget.isMe) ...[
          6.horizontalSpace,
          _buildStatusIcon(),
        ],
      ],
    );
  }

  Widget _buildReactionSummary(bool isDarkMode) {
    final counts = <String, int>{};
    for (final emoji in widget.message.reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }

    final currentReaction = widget.currentUid == null ? null : widget.message.reactions[widget.currentUid];
    final chipBackground = isDarkMode ? const Color(0xFF1F2C34) : Colors.white;
    final chipBorderColor = widget.isMe
        ? (isDarkMode ? Colors.white.withValues(alpha: 0.12) : AppColor.primaryColor.withValues(alpha: 0.22))
        : (isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08));

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 132.w),
      child: Wrap(
        spacing: 3.w,
        runSpacing: 3.h,
        children: counts.entries.map((entry) {
          final isMine = currentReaction == entry.key;

          return Container(
            constraints: BoxConstraints(minHeight: 18.r, minWidth: 18.r),
            padding: EdgeInsets.symmetric(
              horizontal: entry.value > 1 ? 7.w : 4.w,
              vertical: 2.h,
            ),
            decoration: BoxDecoration(
              color: chipBackground,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isMine ? AppColor.primaryColor.withValues(alpha: 0.75) : chipBorderColor,
                width: isMine ? 1.1 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.28 : 0.14,
                  ),
                  blurRadius: 3.r,
                  offset: Offset(0, 1.h),
                ),
              ],
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                entry.value > 1 ? '${entry.key} ${entry.value}' : entry.key,
                style: TextStyle(fontSize: 10.sp, height: 1.0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isSearchMatch() {
    final query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return false;

    return (widget.message.text ?? '').toLowerCase().contains(query) ||
        (widget.message.replyToText ?? '').toLowerCase().contains(query) ||
        _messageTypeLabel(widget.message.type).toLowerCase().contains(query);
  }

  bool _isMentionedCurrentUser() {
    final uid = widget.currentUid;
    if (uid == null || uid.isEmpty) return false;
    return widget.message.mentionedUserIds.contains(uid);
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

    if (query.isNotEmpty && text.toLowerCase().contains(query.toLowerCase()) == true) {
      return _buildSearchHighlightedText(
        text: text,
        color: color,
        fontSize: fontSize,
        maxLines: maxLines,
        overflow: overflow,
        query: query,
      );
    }

    final mentionNames = widget.message.mentionedUserNames.where((name) => name.trim().isNotEmpty).toList();
    if (mentionNames.isEmpty) {
      return Text(
        text,
        softWrap: true,
        textAlign: TextAlign.left,
        maxLines: maxLines,
        overflow: overflow,
        style: textStyle,
      );
    }

    return _buildMentionHighlightedText(
      text: text,
      textStyle: textStyle,
      mentionNames: mentionNames,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  Widget _buildSearchHighlightedText({
    required String text,
    required Color color,
    required double fontSize,
    required String query,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
  }) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
    );

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

  Widget _buildMentionHighlightedText({
    required String text,
    required TextStyle textStyle,
    required List<String> mentionNames,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
  }) {
    final spans = <TextSpan>[];
    final mentionMatches = <_TextMatch>[];
    final lowerText = text.toLowerCase();
    final mentionColor = _mentionTextColor();
    final mentionBackgroundColor = _mentionBackgroundColor();

    for (final name in mentionNames) {
      final needle = '@${name.toLowerCase()}';
      var start = 0;
      while (start < lowerText.length) {
        final index = lowerText.indexOf(needle, start);
        if (index == -1) break;
        mentionMatches.add(_TextMatch(index, index + needle.length));
        start = index + needle.length;
      }
    }

    mentionMatches.sort((a, b) => a.start.compareTo(b.start));
    var cursor = 0;
    for (final match in mentionMatches) {
      if (match.start < cursor) continue;
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: TextStyle(
            color: mentionColor,
            fontWeight: FontWeight.w700,
            backgroundColor: mentionBackgroundColor,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
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

  Color _mentionTextColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return const Color(0xFF6BDDF2);
    return const Color(0xFF007A63);
  }

  Color _mentionBackgroundColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _mentionTextColor().withValues(alpha: isDark ? 0.18 : 0.12);
  }

  String _messageTypeLabel(MessageType type) {
    if (type == MessageType.image) return AppTranslationKey.photo.tr;
    if (type == MessageType.video) return AppTranslationKey.video.tr;
    if (type == MessageType.call) return AppTranslationKey.call.tr;
    if (type == MessageType.file) return AppTranslationKey.document.tr;
    if (type == MessageType.contact) return AppTranslationKey.contact.tr;
    if (type == MessageType.audio) return AppTranslationKey.voiceMessage.tr;
    return AppTranslationKey.message.tr;
  }

  Widget _buildAudioContent(
    Color messageTextColor,
    Color metaTextColor, {
    required String? localAudioPath,
    required String? audioUrl,
  }) {
    final duration = _resolvedAudioDuration();
    final position = _audioPosition > duration ? duration : _audioPosition;
    final progress = duration.inMilliseconds <= 0 ? 0.0 : position.inMilliseconds / duration.inMilliseconds;
    final attachmentAccentColor = _attachmentAccentColor();
    final attachmentBackgroundColor = _attachmentBackgroundColor();
    final attachmentTrackColor = _attachmentTrackColor();

    return SizedBox(
      width: 220.w,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: attachmentBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: widget.message.status == MessageStatus.pending
                  ? null
                  : () => _toggleAudioPlayback(
                        localAudioPath: localAudioPath,
                        audioUrl: audioUrl,
                      ),
              icon: Icon(
                _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                size: 22.r,
                color: attachmentAccentColor,
              ),
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    minHeight: 4.h,
                    value: widget.message.status == MessageStatus.pending ? null : progress.clamp(0.0, 1.0),
                    backgroundColor: attachmentTrackColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      attachmentAccentColor,
                    ),
                  ),
                ),
                6.verticalSpace,
                Text(
                  _formatDuration(_isAudioPlaying ? position : duration),
                  style: TextStyle(
                    color: metaTextColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Duration _resolvedAudioDuration() {
    if (_audioDuration.inMilliseconds > 0) return _audioDuration;
    final seconds = widget.message.audioDurationSeconds ?? 0;
    return Duration(seconds: seconds);
  }

  Color _attachmentAccentColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!widget.isMe) return AppColor.primaryColor;
    return isDark ? Colors.white.withValues(alpha: 0.92) : AppColor.primaryColor;
  }

  Color _attachmentBackgroundColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!widget.isMe) {
      return AppColor.primaryColor.withValues(alpha: isDark ? 0.18 : 0.12);
    }

    return isDark ? Colors.white.withValues(alpha: 0.14) : AppColor.primaryColor.withValues(alpha: 0.12);
  }

  Color _attachmentTrackColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!widget.isMe) {
      return isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.08);
    }

    return isDark ? Colors.white.withValues(alpha: 0.24) : AppColor.primaryColor.withValues(alpha: 0.18);
  }

  Future<void> _toggleAudioPlayback({
    required String? localAudioPath,
    required String? audioUrl,
  }) async {
    final audioPlayer = _ensureAudioPlayer();

    if (_isAudioPlaying) {
      await audioPlayer.pause();
      return;
    }

    if (_audioPosition.inMilliseconds > 0 && _audioPosition < _resolvedAudioDuration()) {
      await audioPlayer.resume();
      return;
    }

    if (localAudioPath != null) {
      await audioPlayer.play(DeviceFileSource(localAudioPath));
      return;
    }

    if (audioUrl != null) {
      await audioPlayer.play(UrlSource(audioUrl));
    }
  }

  Widget _buildFileContent(Color messageTextColor, Color metaTextColor) {
    final fileName = widget.message.fileName ?? AppTranslationKey.document.tr;
    final fileMeta = [
      if (widget.message.fileExtension?.isNotEmpty == true) widget.message.fileExtension,
      if (widget.message.fileSize != null) _formatBytes(widget.message.fileSize!),
    ].whereType<String>().join(' • ');
    final attachmentAccentColor = _attachmentAccentColor();
    final attachmentBackgroundColor = _attachmentBackgroundColor();

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
              color: attachmentBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              size: 20.r,
              color: attachmentAccentColor,
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
    final contactName = widget.message.contactName ?? AppTranslationKey.contact.tr;
    final contactPhone = widget.message.contactPhone ?? '';
    final attachmentAccentColor = _attachmentAccentColor();
    final attachmentBackgroundColor = _attachmentBackgroundColor();

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
              color: attachmentBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 20.r,
              color: attachmentAccentColor,
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
    final attachmentAccentColor = _attachmentAccentColor();
    final attachmentBackgroundColor = _attachmentBackgroundColor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
            color: attachmentBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isVideo ? Icons.videocam_outlined : Icons.call_outlined,
            size: 18.r,
            color: attachmentAccentColor,
          ),
        ),
        8.horizontalSpace,
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVideo ? AppTranslationKey.videoCall.tr : AppTranslationKey.voiceCall.tr,
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
    if (status == 'declined') return AppTranslationKey.declined.tr;
    if (status == 'missed') return AppTranslationKey.missed.tr;
    if (status == 'calling' || status == 'ringing') {
      return AppTranslationKey.ongoing.tr;
    }

    final seconds = widget.message.callDurationSeconds ?? 0;
    if (seconds <= 0) return AppTranslationKey.ended.tr;

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes <= 0) {
      return AppTranslationKey.seconds.trParams({'count': '$remainingSeconds'});
    }
    return AppTranslationKey.minutesSeconds.trParams({
      'minutes': '$minutes',
      'seconds': remainingSeconds.toString().padLeft(2, '0'),
    });
  }

  Widget _buildReplyPreview(Color messageTextColor, Color metaTextColor) {
    final preview = Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
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
          Flexible(
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

    if (widget.onReplyPreviewTap == null) return preview;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onReplyPreviewTap,
      child: preview,
    );
  }

  String _replyPreviewText() {
    final text = widget.message.replyToText?.trim();
    if (text != null && text.isNotEmpty) return text;
    if (widget.message.replyToType == MessageType.image) {
      return AppTranslationKey.photo.tr;
    }
    if (widget.message.replyToType == MessageType.video) {
      return AppTranslationKey.video.tr;
    }
    if (widget.message.replyToType == MessageType.file) {
      return AppTranslationKey.document.tr;
    }
    if (widget.message.replyToType == MessageType.contact) {
      return AppTranslationKey.contact.tr;
    }
    if (widget.message.replyToType == MessageType.audio) {
      return AppTranslationKey.voiceMessage.tr;
    }
    return AppTranslationKey.message.tr;
  }

  String _replySenderName() {
    if (widget.message.replyToSenderId != null && widget.message.replyToSenderId == widget.currentUid) {
      return AppTranslationKey.you.tr;
    }

    return widget.targetName ?? widget.message.replyToSenderName ?? AppTranslationKey.contact.tr;
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
            cacheWidth: _previewCacheWidth(),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildBrokenImage(),
          )
        else if (imageUrl != null)
          Image.network(
            height: 200.h,
            width: double.infinity,
            imageUrl,
            cacheWidth: _previewCacheWidth(),
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

  int _previewCacheWidth() {
    final logicalWidth = MediaQuery.of(context).size.width * 0.8;
    final physicalWidth = logicalWidth * MediaQuery.of(context).devicePixelRatio;
    return physicalWidth.round().clamp(320, 1080);
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
                  AppTranslationKey.video.tr,
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
    final mediaItems = _mediaViewerItems();
    final initialIndex = _mediaInitialIndex(mediaItems);

    Get.toNamed(
      AppRouteName.VIDEO_VIEWER_SCREEN,
      arguments: VideoViewerArgument(
        videoUrl: videoUrl,
        localVideoPath: localVideoPath,
        heroTag: _videoHeroTag(videoUrl, localVideoPath),
        mediaItems: mediaItems,
        initialIndex: initialIndex,
      ),
    );
  }

  void _openImageViewer() {
    final imageUrl = widget.message.imageUrl;
    final localImagePath = _existingFilePath(widget.message.localImagePath);
    if (imageUrl == null && localImagePath == null) return;

    final heroTag = imageUrl ?? localImagePath ?? widget.message.id;
    final mediaItems = _mediaViewerItems();
    final initialIndex = _mediaInitialIndex(mediaItems);

    Get.toNamed(
      AppRouteName.IMAGE_VIEWER_SCREEN,
      arguments: ImageViewerArgument(
        imageUrl: imageUrl,
        localImagePath: localImagePath,
        heroTag: heroTag,
        mediaItems: mediaItems,
        initialIndex: initialIndex,
      ),
    );
  }

  List<MediaViewerItem> _mediaViewerItems() {
    final sourceMessages = widget.mediaMessages.isNotEmpty ? widget.mediaMessages : [widget.message];

    return sourceMessages
        .where(_isViewableMediaMessage)
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

  int _mediaInitialIndex(List<MediaViewerItem> items) {
    final index = items.indexWhere(
      (item) => item.heroTag == _mediaHeroTag(widget.message),
    );
    return index < 0 ? 0 : index;
  }

  bool _isViewableMediaMessage(ChatMessageModel message) {
    if (message.type == MessageType.image) {
      return message.imageUrl?.isNotEmpty == true || _existingFilePath(message.localImagePath) != null;
    }

    if (message.type == MessageType.video) {
      return message.videoUrl?.isNotEmpty == true || _existingFilePath(message.localVideoPath) != null;
    }

    return false;
  }

  String _mediaHeroTag(ChatMessageModel message) {
    if (message.type == MessageType.video) {
      return _videoHeroTag(message.videoUrl, _existingFilePath(message.localVideoPath));
    }

    return message.imageUrl ?? _existingFilePath(message.localImagePath) ?? message.id;
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
        AppTranslationKey.chat.tr,
        result.message.isEmpty ? AppTranslationKey.fileOpenFailed.tr : result.message,
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final neutralColor = isDark ? Colors.white70 : const Color(0xFF667781);

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
        color: neutralColor,
      );
    }

    final uiStatus = _resolveUiStatus();

    switch (uiStatus) {
      case UiMessageStatus.sent:
        return Icon(
          Icons.check,
          size: 12.sp,
          color: neutralColor,
        );

      case UiMessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 12.sp,
          color: neutralColor,
        );

      case UiMessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 12.sp,
          color: const Color(0xFF53BDEB),
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
