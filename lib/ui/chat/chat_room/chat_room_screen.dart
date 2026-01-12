import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/di/injection.dart';

import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_bubble_widget.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_keyboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatRoomArgument {
  final String roomId;
  final String currentUid;
  final UserModel targetUser;

  const ChatRoomArgument({
    required this.roomId,
    required this.currentUid,
    required this.targetUser,
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
    final id = argument?.targetUser.id;

    if (argument == null || id == null) return;

    store.init(
      roomId: argument!.roomId,
      currentUid: argument!.currentUid,
      targetUid: id,
    );
  }

  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      titleSpacing: 0,
      title: Observer(
        builder: (_) {
          final targerUserCallback = argument?.targetUser;
          if (targerUserCallback == null) return SizedBox.shrink();
          final user = store.targetUser?.value ?? targerUserCallback;

          return Row(
            children: [
              _buildAvatarSection(user),
              12.horizontalSpace,
              _buildDisplayNameSections(user),
            ],
          );
        },
      ),
      elevation: 2,
    );
  }

  Widget _buildAvatarSection(UserModel user) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50.r),
      child: CachedNetworkImage(
        height: 36.r,
        width: 36.r,
        imageUrl: user.photoUrl ?? AppStrings.dummyNetworkImage,
      ),
    );
  }

  Widget _buildDisplayNameSections(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: TextStyle(fontSize: 16.sp),
        ),
        4.verticalSpace,
        Text(
          user.isOnline == true ? 'Online' : (user.lastOnlineAt?.hhmm ?? ''),
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (argument == null) return const SizedBox.shrink();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _buildAppbar(),
      body: Column(
        children: [
          Expanded(
            child: Observer(
              builder: (_) {
                final messages = store.messages;

                return ListView.builder(
                  padding: const EdgeInsets.all(16).r,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMe = message.senderId == argument!.currentUid;

                    return ChatBubbleWidget(
                      message: message,
                      isMe: isMe,
                      onRetry: message.status == MessageStatus.failed ? () => store.sendMessage(message.text) : null,
                    );
                  },
                );
              },
            ),
          ),
          ChatKeyboardWidget(store: store),
        ],
      ),
    );
  }
}
