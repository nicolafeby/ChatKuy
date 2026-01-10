import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_keyboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  ChatRoomStore store = ChatRoomStore();

  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _buildAppbar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: store.messages.length,
              reverse: true, // biasanya chat dibalik
              itemBuilder: (context, index) {
                return Text(store.messages[index]);
              },
            ),
          ),
          ChatKeyboardWidget(store: store)
        ],
      ),
    );
  }
}
