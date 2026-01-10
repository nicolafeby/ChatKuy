import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatkuy/core/constants/app_strings.dart';

import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_keyboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatRoomArgument {
  final ChatRoomStore store;
  final String roomId;
  final String currentUid;

  const ChatRoomArgument({
    required this.store,
    required this.roomId,
    required this.currentUid,
  });
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  ChatRoomArgument? argument;

  @override
  void initState() {
    super.initState();

    argument = Get.arguments as ChatRoomArgument?;

    /// SAFETY CHECK
    if (argument == null) return;

    /// currentUid SUDAH DI-INJECT SAAT NAVIGATE
    /// (diambil dari AuthRepository sebelumnya)
    argument!.store.init(
      roomId: argument!.roomId,
      currentUid: argument!.currentUid,
    );
  }

  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          _buildAvatarSection(),
          12.horizontalSpace,
          _buildDisplayNameSections(),
        ],
      ),
      elevation: 2,
    );
  }

  Widget _buildAvatarSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50.r),
      child: CachedNetworkImage(
        height: 36.r,
        width: 36.r,
        imageUrl: AppStrings.dummyNetworkImage,
      ),
    );
  }

  Widget _buildDisplayNameSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nama Pengguna',
          style: TextStyle(fontSize: 16.sp),
        ),
        4.verticalSpace,
        Text(
          'Terakhir online 23:00',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        )
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: argument!.store.messages?.value?.length ?? 0,
              itemBuilder: (context, index) {
                final messages = argument!.store.messages?.value;
                if (messages == null) return const SizedBox.shrink();

                return Text(messages[index].text);
              },
            ),
          ),
          ChatKeyboardWidget(store: argument!.store),
        ],
      ),
    );
  }
}
