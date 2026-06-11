import 'dart:async';
import 'dart:io';

import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/chat_field/attachment_overlay.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/widgets/chat_field/chat_field.dart';
import 'package:chatkuy/core/widgets/skeleton.dart';
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
import 'package:chatkuy/ui/chat/chat_room/widget/chat_unread_separator.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_group_info_screen.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_media_gallery_screen.dart';
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
  final bool isGroup;
  final String? targetMessageId;
  final String? initialHighlightQuery;

  // explisit for notification
  final String? senderId;

  const ChatRoomArgument({
    required this.roomId,
    required this.currentUid,
    this.targetUser,
    this.isGroup = false,
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
  String? _jumpHighlightedMessageId;
  bool _isSearching = false;
  bool _targetScrollScheduled = false;
  bool _didScrollToTarget = false;
  bool _canPopRoute = false;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ChatRoomArgument?;

    final id = argument?.isGroup == true
        ? null
        : argument?.targetUser?.id ?? argument?.senderId;

    if (argument == null || (!argument!.isGroup && id == null)) return;

    store.init(
      roomId: argument!.roomId,
      currentUid: argument!.currentUid,
      targetUid: id,
      isGroup: argument!.isGroup,
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
        final isGroup = argument!.isGroup;
        final activeRoom = store.room?.value;
        final targetId =
            isGroup ? null : argument!.targetUser?.id ?? argument!.senderId;

        bool isTargetTyping() {
          final typingMap = store.typing?.value ?? {};
          if (targetId == null) return false;
          return typingMap[targetId] == true;
        }

        final targetUserFallback = argument?.targetUser;
        final groupMembers = store.groupMembers?.value ?? const <UserModel>[];
        final user = isGroup
            ? UserModel(
                id: argument!.roomId,
                name: activeRoom?.name ?? targetUserFallback?.name ?? 'Grup',
                email: '',
                photoUrl: activeRoom?.photoUrl ?? targetUserFallback?.photoUrl,
                isEmailVerified: false,
                fcmToken: '',
                isOnlineStatusVisible: false,
              )
            : store.targetUser?.value ?? targetUserFallback;
        final currentUser = store.currentUser?.value;
        final canViewPresence = !isGroup &&
            currentUser?.isOnlineStatusVisible == true &&
            user?.isOnlineStatusVisible != false;

        final messages = _isSearching ? store.visibleMessages : store.messages;
        final isInitialMessagesLoading =
            !_isSearching && store.isInitialMessagesLoading.value;
        _scheduleTargetMessageScroll(messages);
        final isSelectionMode = _selectedMessageIds.isNotEmpty;
        if (isSelectionMode) {
          final visibleMessageIds =
              messages.map((message) => message.id).toSet();
          _selectedMessageIds.removeWhere(
            (messageId) => !visibleMessageIds.contains(messageId),
          );
        }
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
                        isGroup: isGroup,
                        subtitle: isGroup ? _groupSubtitle(groupMembers) : null,
                        onSearchTap: _showSearch,
                        onProfileTap: isGroup
                            ? _openGroupInfoScreen
                            : user == null || targetId == null
                                ? null
                                : () => Get.toNamed(
                                      AppRouteName.USER_PROFILE_SCREEN,
                                      arguments: UserProfileArgument(
                                        targetUser: user,
                                        roomId: argument!.roomId,
                                        currentUid: argument!.currentUid,
                                      ),
                                    ),
                        onAddMembersTap: isGroup ? _openGroupInfoScreen : null,
                        onGroupInfoTap: isGroup ? _openGroupInfoScreen : null,
                        onGroupMediaTap: isGroup
                            ? () => Get.toNamed(
                                  AppRouteName.CHAT_MEDIA_GALLERY_SCREEN,
                                  arguments: ChatMediaGalleryArgument(
                                    roomName: user?.name ?? 'Grup',
                                    messages: store.messages,
                                    roomId: argument!.roomId,
                                  ),
                                )
                            : null,
                        onCallTap: isGroup || user == null || targetId == null
                            ? null
                            : () =>
                                _startCall(user, targetId, isVideoCall: false),
                        onVideoCallTap: isGroup ||
                                user == null ||
                                targetId == null
                            ? null
                            : () =>
                                _startCall(user, targetId, isVideoCall: true),
                      ),
            body: Stack(
              children: [
                const Positioned.fill(child: _ChatWallpaper()),
                Column(
                  children: [
                    Expanded(
                      child: isInitialMessagesLoading
                          ? const ChatRoomSkeletonView()
                          : messages.isEmpty && hasSearchQuery
                              ? Center(
                                  child: Text(
                                      AppTranslationKey.messageNotFound.tr),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.fromLTRB(
                                      10.w, 8.h, 10.w, 12.h),
                                  reverse: true,
                                  cacheExtent: 600,
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final realIndex =
                                        messages.length - 1 - index;

                                    final message = messages[realIndex];
                                    final localMediaPath =
                                        _localMediaPath(message);
                                    final isMe = message.senderId ==
                                        argument!.currentUid;
                                    final isSelected = _selectedMessageIds
                                        .contains(message.id);

                                    final prevMessage = realIndex > 0
                                        ? messages[realIndex - 1]
                                        : null;

                                    final isSameGroup = prevMessage != null &&
                                        prevMessage.senderId ==
                                            message.senderId &&
                                        message.createdAt
                                            .isSameDay(prevMessage.createdAt);

                                    final showDateSeparator = prevMessage ==
                                            null ||
                                        !message.createdAt
                                            .isSameDay(prevMessage.createdAt);
                                    final showUnreadDivider = !_isSearching &&
                                        store.unreadDividerMessageId.value ==
                                            message.id;
                                    final uploadProgress = store
                                                .uploadProgressByMessageId[
                                            message.id] ??
                                        (localMediaPath == null
                                            ? null
                                            : store.uploadProgressByLocalPath[
                                                localMediaPath]);
                                    final sender = isGroup && !isMe
                                        ? _memberById(
                                            groupMembers,
                                            message.senderId,
                                          )
                                        : null;

                                    return Column(
                                      key: _keyForMessage(message.id),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (showDateSeparator)
                                          ChatDateSeparator(
                                            label:
                                                message.createdAt.chatDayLabel,
                                          ).paddingOnly(top: 8.h),
                                        if (showUnreadDivider)
                                          ChatUnreadSeparator(
                                            label: AppTranslationKey
                                                .unreadMessages.tr,
                                          ),
                                        ChatBubbleWidget(
                                          message: message,
                                          isMe: isMe,
                                          uploadProgress: uploadProgress,
                                          isSameGroup: isSameGroup,
                                          isFirstInGroup: !isSameGroup,
                                          currentUid: argument!.currentUid,
                                          targetName: user?.name,
                                          showSenderInfo: isGroup && !isMe,
                                          senderUser: sender,
                                          senderName: sender?.name ??
                                              message.senderName,
                                          senderPhotoUrl: sender?.photoUrl,
                                          mediaMessages:
                                              _mediaMessages(store.messages),
                                          onSenderAvatarTap: sender == null
                                              ? null
                                              : () => Get.toNamed(
                                                    AppRouteName
                                                        .USER_PROFILE_SCREEN,
                                                    arguments:
                                                        UserProfileArgument(
                                                      targetUser: sender,
                                                      roomId: argument!.roomId,
                                                      currentUid:
                                                          argument!.currentUid,
                                                    ),
                                                  ),
                                          searchQuery: _activeHighlightQuery,
                                          isJumpHighlighted:
                                              _jumpHighlightedMessageId ==
                                                  message.id,
                                          onRetry: message.status ==
                                                  MessageStatus.failed
                                              ? () => _retryMessage(message)
                                              : null,
                                          onReply: !isSelectionMode &&
                                                  message.status ==
                                                      MessageStatus.sent
                                              ? () => store
                                                  .setReplyToMessage(message)
                                              : null,
                                          onReplyPreviewTap: !isSelectionMode
                                              ? () =>
                                                  _jumpToRepliedMessage(message)
                                              : null,
                                          onDelete: () =>
                                              _deleteMessageForMe(message),
                                          onSelect: () =>
                                              _toggleSelectedMessage(
                                                  message.id),
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
                              _buildMentionSuggestions(),
                              ChatFieldV2(
                                controller: store.messageController,
                                sendButtonColor: AppColor.primaryColor,
                                attachmentConfig: AttachmentConfig(
                                  showAudio: false,
                                  backgroundColor:
                                      Colors.grey.withValues(alpha: 0.7),
                                ),
                                onSendTap: () {
                                  final text =
                                      store.messageController.text.trim();
                                  if (text.isEmpty) return;
                                  store.sendMessage(text, null);
                                },
                                onChanged: (value) {
                                  store.onTypingChanged(value);
                                  if (argument?.isGroup == true) {
                                    setState(() {});
                                  }
                                },
                                store: store,
                              ),
                            ],
                          );
                        },
                      ),
                  ],
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

  Widget _buildMentionSuggestions() {
    if (argument?.isGroup != true) return const SizedBox.shrink();

    final suggestions = store.mentionSuggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((user) {
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: ActionChip(
                label: Text('@${user.name}'),
                avatar: CircleAvatar(
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                  ),
                ),
                onPressed: () {
                  store.insertMention(user);
                  setState(() {});
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _openGroupInfoScreen() {
    final roomId = argument?.roomId;
    final currentUid = argument?.currentUid;
    if (roomId == null || currentUid == null) return;

    Get.toNamed(
      AppRouteName.CHAT_GROUP_INFO_SCREEN,
      arguments: ChatGroupInfoArgument(
        roomId: roomId,
        currentUid: currentUid,
      ),
    );
  }

  String _groupSubtitle(List<UserModel> members) {
    if (members.isEmpty) return 'Group';

    final names = members.take(4).map((member) {
      if (member.id == argument?.currentUid) return 'You';
      return member.name;
    }).toList();

    if (members.length > names.length) {
      names.add('+${members.length - names.length}');
    }

    return names.join(', ');
  }

  UserModel? _memberById(List<UserModel> members, String uid) {
    for (final member in members) {
      if (member.id == uid) return member;
    }
    return null;
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final didScroll = await _scrollToMessage(
        targetMessageId: targetMessageId,
        realIndex: realIndex,
        visibleMessageCount: messages.length,
      );

      if (!mounted) return;
      if (didScroll) {
        _didScrollToTarget = true;
        _flashJumpHighlight(targetMessageId);
      } else {
        _targetScrollScheduled = false;
      }
    });
  }

  Future<bool> _scrollToMessage({
    required String targetMessageId,
    required int realIndex,
    required int visibleMessageCount,
  }) async {
    if (!mounted) return false;

    if (!_scrollController.hasClients) {
      return false;
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
      if (!mounted) return false;

      final context = _messageKeys[targetMessageId]?.currentContext;
      if (context != null) {
        if (!context.mounted) return false;

        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: 0.48,
        );
        return true;
      }

      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    return false;
  }

  void _jumpToRepliedMessage(ChatMessageModel message) {
    final targetMessageId = message.replyToMessageId;
    if (targetMessageId == null) return;

    final messages = store.messages;
    final realIndex = messages.indexWhere(
      (message) => message.id == targetMessageId,
    );
    if (realIndex == -1) {
      Get.snackbar(
        AppTranslationKey.chat.tr,
        AppTranslationKey.messageNotFound.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _highlightQuery = '';
      _jumpHighlightedMessageId = null;
      _selectedMessageIds.clear();

      if (_isSearching) {
        _isSearching = false;
        _searchController.clear();
        store.clearSearch();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final didScroll = await _scrollToMessage(
        targetMessageId: targetMessageId,
        realIndex: realIndex,
        visibleMessageCount: messages.length,
      );

      if (!mounted) return;
      if (didScroll) {
        _flashJumpHighlight(targetMessageId);
        return;
      }

      Get.snackbar(
        AppTranslationKey.chat.tr,
        AppTranslationKey.messageNotFound.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

  void _flashJumpHighlight(String messageId) {
    setState(() {
      _jumpHighlightedMessageId = messageId;
    });

    Timer(const Duration(milliseconds: 1600), () {
      if (!mounted || _jumpHighlightedMessageId != messageId) return;
      setState(() {
        _jumpHighlightedMessageId = null;
      });
    });
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

  List<ChatMessageModel> _mediaMessages(List<ChatMessageModel> messages) {
    return messages.where((message) {
      if (message.type == MessageType.image) {
        return message.imageUrl?.isNotEmpty == true ||
            _existingFilePath(message.localImagePath) != null;
      }

      if (message.type == MessageType.video) {
        return message.videoUrl?.isNotEmpty == true ||
            _existingFilePath(message.localVideoPath) != null;
      }

      return false;
    }).toList();
  }

  String? _existingFilePath(String? path) {
    if (path == null || path.isEmpty) return null;
    return File(path).existsSync() ? path : null;
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

class _ChatWallpaper extends StatelessWidget {
  const _ChatWallpaper();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? AppColor.chatWallpaperDark : AppColor.chatWallpaper,
      child: CustomPaint(
        painter: _ChatWallpaperPainter(isDark: isDark),
      ),
    );
  }
}

class _ChatWallpaperPainter extends CustomPainter {
  const _ChatWallpaperPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF667781))
          .withValues(alpha: isDark ? 0.035 : 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF667781))
          .withValues(alpha: isDark ? 0.025 : 0.04);

    const spacing = 56.0;
    for (var y = 24.0; y < size.height + spacing; y += spacing) {
      for (var x = 20.0; x < size.width + spacing; x += spacing) {
        final shiftedX = x + ((y ~/ spacing).isEven ? 0 : spacing / 2);
        canvas.drawCircle(Offset(shiftedX, y), 7, paint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(shiftedX + 16, y + 12), radius: 8),
          0.2,
          2.6,
          false,
          paint,
        );
        canvas.drawCircle(Offset(shiftedX - 14, y + 18), 2.4, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatWallpaperPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
