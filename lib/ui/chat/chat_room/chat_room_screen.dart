import 'dart:io';

import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/chat_field/attachment_overlay.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/widgets/chat_field/chat_field.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/di/injection.dart';

import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/attachment_model.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_appbar_widget.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_bubble_widget.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_date_sparator.dart';
import 'package:chatkuy/ui/chat/call/call_argument.dart';
import 'package:chatkuy/ui/profile/user_profile_screen.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatRoomArgument {
  final String roomId;
  final String currentUid;
  final UserModel? targetUser;
  final String? targetMessageId;
  final String? initialHighlightQuery;

  // explisit for notification
  final String? senderId;

  const ChatRoomArgument({
    required this.roomId,
    required this.currentUid,
    this.targetUser,
    this.targetMessageId,
    this.initialHighlightQuery,
    this.senderId,
  });
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with AutomaticKeepAliveClientMixin {
  ChatRoomStore store = ChatRoomStore(
    chatRepository: getIt<ChatRepository>(),
    userRepository: getIt<UserRepository>(),
  );

  ChatRoomArgument? argument;
  final Set<String> _selectedMessageIds = {};
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  String _highlightQuery = '';
  bool _isSearching = false;
  bool _targetScrollScheduled = false;
  bool _didScrollToTarget = false;
  bool _canPopRoute = false;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ChatRoomArgument?;

    final id = argument?.targetUser?.id ?? argument?.senderId;

    if (argument == null || id == null) return;

    store.init(
      roomId: argument!.roomId,
      currentUid: argument!.currentUid,
      targetUid: id,
    );

    _highlightQuery = argument?.initialHighlightQuery?.trim() ?? '';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    store.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_selectedMessageIds.isNotEmpty) {
      _clearSelectedMessages();
      return;
    }

    if (_isSearching) {
      _hideSearch();
      return;
    }

    if (AttachmentOverlay.isShowing) {
      AttachmentOverlay.hide();
      return;
    }

    if (ChatFieldV2.isEmojiShowing) {
      ChatFieldV2.setEmojiShowing(false);
      return;
    }

    if (!mounted) return;

    setState(() {
      _canPopRoute = true;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (argument == null) return const SizedBox.shrink();

    return Observer(
      builder: (context) {
        final targetId = argument!.targetUser?.id ?? argument!.senderId;

        bool isTargetTyping() {
          final typingMap = store.typing?.value ?? {};
          if (targetId == null) return false;
          return typingMap[targetId] == true;
        }

        final targetUserFallback = argument?.targetUser;
        final user = store.targetUser?.value ?? targetUserFallback;
        final currentUser = store.currentUser?.value;
        final canViewPresence = currentUser?.isOnlineStatusVisible == true &&
            user?.isOnlineStatusVisible != false;

        final messages = _isSearching ? store.visibleMessages : store.messages;
        _scheduleTargetMessageScroll(messages);
        final visibleMessageIds = messages.map((message) => message.id).toSet();
        _selectedMessageIds.removeWhere(
          (messageId) => !visibleMessageIds.contains(messageId),
        );
        final isSelectionMode = _selectedMessageIds.isNotEmpty;
        final hasSearchQuery =
            _isSearching && store.searchQuery.trim().isNotEmpty;

        final dummy = UserModel(
          name: 'name',
          email: 'email',
          isEmailVerified: false,
          fcmToken: 'fcmToken',
        );

        return PopScope(
          canPop: _canPopRoute,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBack();
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: isSelectionMode
                ? _buildSelectionAppBar(messages)
                : _isSearching
                    ? _buildSearchAppBar()
                    : ChatAppbarWidget(
                        store: store,
                        userData: user ?? dummy,
                        isTyping: canViewPresence && isTargetTyping(),
                        canViewPresence: canViewPresence,
                        onSearchTap: _showSearch,
                        onProfileTap: user == null || targetId == null
                            ? null
                            : () => Get.toNamed(
                                  AppRouteName.USER_PROFILE_SCREEN,
                                  arguments: UserProfileArgument(
                                    targetUser: user,
                                    roomId: argument!.roomId,
                                    currentUid: argument!.currentUid,
                                  ),
                                ),
                        onCallTap: user == null || targetId == null
                            ? null
                            : () =>
                                _startCall(user, targetId, isVideoCall: false),
                        onVideoCallTap: user == null || targetId == null
                            ? null
                            : () =>
                                _startCall(user, targetId, isVideoCall: true),
                      ),
            body: Column(
              children: [
                Expanded(
                  child: messages.isEmpty && hasSearchQuery
                      ? Center(
                          child: Text(AppTranslationKey.messageNotFound.tr),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16).r,
                          reverse: true,
                          cacheExtent: 600,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final realIndex = messages.length - 1 - index;

                            final message = messages[realIndex];
                            final localMediaPath = _localMediaPath(message);
                            final isMe =
                                message.senderId == argument!.currentUid;
                            final isSelected =
                                _selectedMessageIds.contains(message.id);

                            final prevMessage =
                                realIndex > 0 ? messages[realIndex - 1] : null;

                            final isSameGroup = prevMessage != null &&
                                prevMessage.senderId == message.senderId;

                            final showDateSeparator = prevMessage == null ||
                                !message.createdAt
                                    .isSameDay(prevMessage.createdAt);
                            final uploadProgress =
                                store.uploadProgressByMessageId[message.id] ??
                                    (localMediaPath == null
                                        ? null
                                        : store.uploadProgressByLocalPath[
                                            localMediaPath]);

                            return Column(
                              key: _keyForMessage(message.id),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDateSeparator)
                                  ChatDateSeparator(
                                    label: message.createdAt.chatDayLabel,
                                  ).paddingOnly(top: 8.h),
                                ChatBubbleWidget(
                                  message: message,
                                  isMe: isMe,
                                  uploadProgress: uploadProgress,
                                  isSameGroup: isSameGroup,
                                  isFirstInGroup: !isSameGroup,
                                  currentUid: argument!.currentUid,
                                  targetName: user?.name,
                                  searchQuery: _activeHighlightQuery,
                                  onRetry:
                                      message.status == MessageStatus.failed
                                          ? () => _retryMessage(message)
                                          : null,
                                  onReply: !isSelectionMode &&
                                          message.status == MessageStatus.sent
                                      ? () => store.setReplyToMessage(message)
                                      : null,
                                  onDelete: () => _deleteMessageForMe(message),
                                  onSelect: () =>
                                      _toggleSelectedMessage(message.id),
                                  selectionMode: isSelectionMode,
                                  isSelected: isSelected,
                                ),
                              ],
                            );
                          },
                        ),
                ),
                if (!_isSearching)
                  Observer(
                    builder: (context) {
                      final replyToMessage = store.replyToMessage.value;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (replyToMessage != null)
                            _ReplyPreviewBar(
                              message: replyToMessage,
                              currentUid: argument!.currentUid,
                              targetName: user?.name,
                              onClose: store.clearReplyToMessage,
                            ),
                          ChatFieldV2(
                            controller: store.messageController,
                            sendButtonColor: AppColor.primaryColor,
                            attachmentConfig: AttachmentConfig(
                              showAudio: false,
                              backgroundColor:
                                  Colors.grey.withValues(alpha: 0.7),
                            ),
                            onSendTap: () {
                              final text = store.messageController.text.trim();
                              if (text.isEmpty) return;
                              store.sendMessage(text, null);
                            },
                            onChanged: store.onTypingChanged,
                            store: store,
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  String get _activeHighlightQuery {
    if (_isSearching) return store.searchQuery;
    return _highlightQuery;
  }

  GlobalKey _keyForMessage(String messageId) {
    return _messageKeys.putIfAbsent(messageId, GlobalKey.new);
  }

  void _scheduleTargetMessageScroll(List<ChatMessageModel> messages) {
    final targetMessageId = argument?.targetMessageId;
    if (targetMessageId == null ||
        _didScrollToTarget ||
        _targetScrollScheduled) {
      return;
    }

    final realIndex = messages.indexWhere(
      (message) => message.id == targetMessageId,
    );
    if (realIndex == -1) return;

    _targetScrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTargetMessage(
        targetMessageId: targetMessageId,
        realIndex: realIndex,
        visibleMessageCount: messages.length,
      );
    });
  }

  Future<void> _scrollToTargetMessage({
    required String targetMessageId,
    required int realIndex,
    required int visibleMessageCount,
  }) async {
    if (!mounted) return;

    if (!_scrollController.hasClients) {
      _targetScrollScheduled = false;
      return;
    }

    final builderIndex = visibleMessageCount - 1 - realIndex;
    final estimatedOffset = (builderIndex * 82.h).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      estimatedOffset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );

    for (var attempt = 0; attempt < 8; attempt++) {
      if (!mounted) return;

      final context = _messageKeys[targetMessageId]?.currentContext;
      if (context != null) {
        if (!context.mounted) return;

        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: 0.48,
        );
        _didScrollToTarget = true;
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    _targetScrollScheduled = false;
  }

  PreferredSizeWidget _buildSelectionAppBar(List<ChatMessageModel> messages) {
    return AppBar(
      leading: IconButton(
        onPressed: _clearSelectedMessages,
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text('${_selectedMessageIds.length}'),
      actions: [
        IconButton(
          tooltip: AppTranslationKey.deleteForMe.tr,
          onPressed: () => _deleteSelectedMessagesForMe(messages),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      leading: IconButton(
        tooltip: AppTranslationKey.closeSearch.tr,
        onPressed: _hideSearch,
        icon: const Icon(Icons.arrow_back),
      ),
      titleSpacing: 4.w,
      title: SizedBox(
        height: 38.h,
        child: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          cursorHeight: 18.h,
          style: TextStyle(fontSize: 14.sp),
          onChanged: store.setSearchQuery,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.72,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide.none,
            ),
            hintText: AppTranslationKey.searchMessages.tr,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14.sp,
            ),
            suffixIconConstraints: BoxConstraints(
              minWidth: 40.w,
              minHeight: 28.h,
            ),
            suffixIcon: store.searchQuery.trim().isEmpty
                ? null
                : Center(
                    widthFactor: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primaryColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${store.searchResultCount}',
                        style: TextStyle(
                          color: AppColor.primaryColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
      actions: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();

            return IconButton(
              tooltip: AppTranslationKey.clearSearch.tr,
              onPressed: () {
                _searchController.clear();
                store.clearSearch();
              },
              icon: const Icon(Icons.close),
            );
          },
        ),
      ],
    );
  }

  void _showSearch() {
    setState(() {
      _isSearching = true;
      _highlightQuery = '';
      _selectedMessageIds.clear();
      store.clearReplyToMessage();
    });
  }

  void _hideSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      store.clearSearch();
    });
  }

  void _toggleSelectedMessage(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _clearSelectedMessages() {
    if (_selectedMessageIds.isEmpty) return;
    setState(_selectedMessageIds.clear);
  }

  String? _localMediaPath(ChatMessageModel message) {
    if (message.type == MessageType.file) return message.localFilePath;
    if (message.type == MessageType.video) return message.localVideoPath;
    if (message.type == MessageType.audio) return message.localAudioPath;
    return message.localImagePath;
  }

  void _retryMessage(ChatMessageModel message) {
    if (message.type == MessageType.audio && message.localAudioPath != null) {
      store.sendAudioMessage(
        audioFile: File(message.localAudioPath!),
        duration: Duration(seconds: message.audioDurationSeconds ?? 1),
      );
      return;
    }

    if (message.type == MessageType.file && message.localFilePath != null) {
      store.sendFileMessage(File(message.localFilePath!));
      return;
    }

    if (message.type == MessageType.video && message.localVideoPath != null) {
      store.sendVideoMessage(message.text, File(message.localVideoPath!));
      return;
    }

    store.sendMessage(
      message.text,
      message.localImagePath == null ? null : File(message.localImagePath!),
    );
  }

  Future<void> _deleteMessageForMe(ChatMessageModel message) async {
    try {
      await store.deleteMessageForMe(message);
    } catch (_) {
      if (!mounted) return;

      Get.snackbar(
        AppTranslationKey.chat.tr,
        AppTranslationKey.somethingWentWrong.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _deleteSelectedMessagesForMe(
    List<ChatMessageModel> messages,
  ) async {
    final selectedMessages = messages
        .where((message) => _selectedMessageIds.contains(message.id))
        .toList();

    if (selectedMessages.isEmpty) {
      _clearSelectedMessages();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslationKey.deleteMessagesTitle.trParams({
          'count': '${selectedMessages.length}',
        })),
        content: Text(AppTranslationKey.deleteMessagesContent.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppTranslationKey.cancel.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppTranslationKey.delete.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await store.deleteMessagesForMe(selectedMessages);
      _clearSelectedMessages();
    } catch (_) {
      if (!mounted) return;

      Get.snackbar(
        AppTranslationKey.chat.tr,
        AppTranslationKey.somethingWentWrong.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _startCall(
    UserModel targetUser,
    String targetId, {
    required bool isVideoCall,
  }) {
    if (argument == null) return;

    Get.toNamed(
      AppRouteName.CALL_SCREEN,
      arguments: CallArgument(
        roomId: argument!.roomId,
        currentUid: argument!.currentUid,
        targetUid: targetId,
        targetName: targetUser.name,
        currentUserName: 'ChatKuy',
        isCaller: true,
        isVideoCall: isVideoCall,
      ),
    );
  }
}

class _ReplyPreviewBar extends StatelessWidget {
  const _ReplyPreviewBar({
    required this.message,
    required this.currentUid,
    required this.onClose,
    this.targetName,
  });

  final ChatMessageModel message;
  final String currentUid;
  final String? targetName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final senderName = message.senderId == currentUid
        ? AppTranslationKey.you.tr
        : (targetName ?? AppTranslationKey.contact.tr);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 0),
      color: colorScheme.surface,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Container(
              width: 3.w,
              height: 38.h,
              decoration: BoxDecoration(
                color: AppColor.primaryColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColor.primaryColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  2.verticalSpace,
                  Text(
                    _previewText(message),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: Icon(
                Icons.close,
                size: 18.r,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _previewText(ChatMessageModel message) {
    final text = message.text?.trim();
    if (text != null && text.isNotEmpty) return text;
    if (message.type == MessageType.image) return AppTranslationKey.photo.tr;
    if (message.type == MessageType.video) return AppTranslationKey.video.tr;
    if (message.type == MessageType.call) return AppTranslationKey.call.tr;
    if (message.type == MessageType.file) return AppTranslationKey.document.tr;
    if (message.type == MessageType.audio) {
      return AppTranslationKey.voiceMessage.tr;
    }
    if (message.type == MessageType.contact) {
      return AppTranslationKey.contact.tr;
    }
    return AppTranslationKey.message.tr;
  }
}
