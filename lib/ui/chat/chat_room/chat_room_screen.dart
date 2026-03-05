import 'package:chatkuy/core/constants/color.dart';
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

class _ChatRoomScreenState extends State<ChatRoomScreen> with AutomaticKeepAliveClientMixin{
  ChatRoomStore store = ChatRoomStore(
    chatRepository: getIt<ChatRepository>(),
    userRepository: getIt<UserRepository>(),
  );

  ChatRoomArgument? argument;

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

        final dummy = UserModel(
          name: 'name',
          email: 'email',
          isEmailVerified: false,
          fcmToken: 'fcmToken',
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (AttachmentOverlay.isShowing) {
              AttachmentOverlay.hide();
            } else if(ChatFieldV2.isEmojiShowing){
              ChatFieldV2.setEmojiShowing(false);
            }
            else {
              Get.back();
            }

          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: ChatAppbarWidget(
              store: store,
              userData: user ?? dummy,
              isTyping: isTargetTyping(),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16).r,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final realIndex = messages.length - 1 - index;

                      final message = messages[realIndex];
                      final isMe = message.senderId == argument!.currentUid;

                      final prevMessage = realIndex > 0 ? messages[realIndex - 1] : null;

                      final isSameGroup = prevMessage != null && prevMessage.senderId == message.senderId;

                      final showDateSeparator =
                          prevMessage == null || !message.createdAt.isSameDay(prevMessage.createdAt);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateSeparator)
                            ChatDateSeparator(
                              label: message.createdAt.chatDayLabel,
                            ).paddingOnly(top: 8.h),
                          ChatBubbleWidget(
                            message: message,
                            isMe: isMe,
                            isSameGroup: isSameGroup,
                            isFirstInGroup: !isSameGroup,
                            onRetry: message.status == MessageStatus.failed
                                ? () => store.sendMessage(message.text, null)
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                ChatFieldV2(
                  controller: store.messageController,
                  sendButtonColor: AppColor.primaryColor,
                  attachmentConfig: AttachmentConfig(
                    showAudio: false,
                    backgroundColor: Colors.grey.withOpacity(0.7),
                  ),
                  onSendTap: () {
                    final text = store.messageController.text.trim();
                    if (text.isEmpty) return;
                    store.sendMessage(text, null);
                  },
                  store: store,
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
}
