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
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatRoomArgument {
  final String roomId;
  final String currentUid;
  final UserModel? targetUser;

  // explisit for notification
  final String? senderId;

  const ChatRoomArgument({
    required this.roomId,
    required this.currentUid,
    this.targetUser,
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
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
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

        final messages = store.messages;
        final visibleMessageIds = messages.map((message) => message.id).toSet();
        _selectedMessageIds.removeWhere(
          (messageId) => !visibleMessageIds.contains(messageId),
        );
        final isSelectionMode = _selectedMessageIds.isNotEmpty;

        final dummy = UserModel(
          name: 'name',
          email: 'email',
          isEmailVerified: false,
          fcmToken: 'fcmToken',
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (_selectedMessageIds.isNotEmpty) {
              _clearSelectedMessages();
            } else if (AttachmentOverlay.isShowing) {
              AttachmentOverlay.hide();
            } else if (ChatFieldV2.isEmojiShowing) {
              ChatFieldV2.setEmojiShowing(false);
            } else {
              Get.back();
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: isSelectionMode
                ? _buildSelectionAppBar(messages)
                : ChatAppbarWidget(
                    store: store,
                    userData: user ?? dummy,
                    isTyping: isTargetTyping(),
                    onCallTap: user == null || targetId == null
                        ? null
                        : () => _startCall(user, targetId, isVideoCall: false),
                    onVideoCallTap: user == null || targetId == null
                        ? null
                        : () => _startCall(user, targetId, isVideoCall: true),
                  ),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16).r,
                    reverse: true,
                    cacheExtent: 600,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final realIndex = messages.length - 1 - index;

                      final message = messages[realIndex];
                      final localMediaPath = _localMediaPath(message);
                      final isMe = message.senderId == argument!.currentUid;
                      final isSelected =
                          _selectedMessageIds.contains(message.id);

                      final prevMessage =
                          realIndex > 0 ? messages[realIndex - 1] : null;

                      final isSameGroup = prevMessage != null &&
                          prevMessage.senderId == message.senderId;

                      final showDateSeparator = prevMessage == null ||
                          !message.createdAt.isSameDay(prevMessage.createdAt);
                      final uploadProgress = store
                              .uploadProgressByMessageId[message.id] ??
                          (localMediaPath == null
                              ? null
                              : store
                                  .uploadProgressByLocalPath[localMediaPath]);

                      return Column(
                        key: ValueKey(message.id),
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
                            onRetry: message.status == MessageStatus.failed
                                ? () => _retryMessage(message)
                                : null,
                            onReply: !isSelectionMode &&
                                    message.status == MessageStatus.sent
                                ? () => store.setReplyToMessage(message)
                                : null,
                            onDelete: () => _deleteMessageForMe(message),
                            onSelect: () => _toggleSelectedMessage(message.id),
                            selectionMode: isSelectionMode,
                            isSelected: isSelected,
                          ),
                        ],
                      );
                    },
                  ),
                ),
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
                            backgroundColor: Colors.grey.withValues(alpha: 0.7),
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

  PreferredSizeWidget _buildSelectionAppBar(List<ChatMessageModel> messages) {
    return AppBar(
      leading: IconButton(
        onPressed: _clearSelectedMessages,
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text('${_selectedMessageIds.length}'),
      actions: [
        IconButton(
          tooltip: 'Hapus untuk saya',
          onPressed: () => _deleteSelectedMessagesForMe(messages),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
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
    if (message.type == MessageType.video) return message.localVideoPath;
    return message.localImagePath;
  }

  void _retryMessage(ChatMessageModel message) {
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
        'Chat',
        'Pesan gagal dihapus',
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
        title: Text('Hapus ${selectedMessages.length} pesan?'),
        content: const Text('Pesan akan dihapus hanya dari chat Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
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
        'Chat',
        'Pesan yang dipilih gagal dihapus',
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
    final senderName =
        message.senderId == currentUid ? 'Anda' : (targetName ?? 'Kontak');

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
    if (message.type == MessageType.image) return 'Foto';
    if (message.type == MessageType.video) return 'Video';
    if (message.type == MessageType.call) return 'Panggilan';
    return 'Pesan';
  }
}
