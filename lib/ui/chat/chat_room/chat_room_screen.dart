import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/di/injection.dart';

import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_appbar_widget.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_bubble_widget.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_date_sparator.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_keyboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatRoomArgument {
  final String roomId;
  final String currentUid;
  final UserModel? targetUser;

  const ChatRoomArgument({
    required this.roomId,
    required this.currentUid,
    this.targetUser,
  });
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  ChatRoomStore store = ChatRoomStore(
    chatRepository: getIt<ChatRepository>(),
    userRepository: getIt<UserRepository>(),
  );
  ChatRoomArgument? argument;

  @override
  void initState() {
    super.initState();

    argument = Get.arguments as ChatRoomArgument?;
    final id = argument?.targetUser?.id;

    if (argument == null || id == null) return;

    store.init(
      roomId: argument!.roomId,
      currentUid: argument!.currentUid,
      targetUid: id,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (argument == null) return const SizedBox.shrink();

    return Observer(
      builder: (context) {
        bool isTargetTyping() {
          final typingMap = store.typing?.value ?? {};
          return typingMap[argument!.targetUser?.id] == true;
        }

        final targerUserCallback = argument?.targetUser;
        if (targerUserCallback == null) return SizedBox.shrink();
        final user = store.targetUser?.value ?? targerUserCallback;

        final messages = store.messages;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: ChatAppbarWidget(
            store: store,
            userData: user,
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

                    if (showDateSeparator) return ChatDateSeparator(label: message.createdAt.chatDayLabel);

                    return ChatBubbleWidget(
                      message: message,
                      isMe: isMe,
                      isSameGroup: isSameGroup,
                      isFirstInGroup: !isSameGroup,
                      onRetry: message.status == MessageStatus.failed ? () => store.sendMessage(message.text) : null,
                    );
                  },
                ),
              ),
              ChatKeyboardWidget(store: store),
            ],
          ),
        );
      },
    );
  }
}
