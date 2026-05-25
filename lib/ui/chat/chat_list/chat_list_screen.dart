import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/repositories/chat_user_list_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/chat/chat_list/chat_user_list_store.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:chatkuy/ui/chat/chat_list/widget/chat_list_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with BaseLayout {
  ChatUserListStore store = ChatUserListStore(
    repository: getIt<ChatUserListRepository>(),
  );

  @override
  void initState() {
    super.initState();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) return;
    store.watchChatUsers(currentUid);
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppbar() {
    final isDarkMode = isDarkModeOf(context);
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Percakapan',
        style: TextStyle(fontSize: 28.sp),
      ),
      actions: [
        Image.asset(
          AppAsset.icEditOutlined,
          height: 24.r,
          color: isDarkMode ? Colors.white : null,
        ).paddingOnly(right: 16.r)
      ],
    );
  }

  Widget _buildBody() {
    final isDark = isDarkModeOf(context);
    return Column(
      children: [
        ChatListSearchWidget()
            .paddingSymmetric(horizontal: 20.r)
            .paddingOnly(bottom: 8.h),

        /// REALTIME CHAT LIST
        Expanded(
          child: Observer(
            builder: (_) {
              if (store.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (store.errorMessage != null) {
                return Center(
                  child: Text(store.errorMessage!),
                );
              }

              if (store.chatUsers.isEmpty) {
                return const Center(
                  child: Text('Belum ada percakapan'),
                );
              }

              return ListView.separated(
                itemCount: store.chatUsers.length,
                separatorBuilder: (_, __) => SizedBox(height: 2.h),
                itemBuilder: (_, index) {
                  final item = store.chatUsers[index];
                  final user = item.user;

                  return ListTile(
                    leading: ProfileAvatarWidget(
                        base64Image: user.photoUrl, size: 48),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(user.name),
                        Text(
                          item.lastMessageAt?.hhmm ?? '',
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark ? null : Colors.black54),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Visibility(
                          visible: item.type == MessageType.image,
                          child: Icon(Icons.image_outlined, size: 18.r)
                              .paddingOnly(right: 4.w),
                        ),
                        Visibility(
                          visible: item.type == MessageType.video,
                          child: Icon(Icons.videocam_outlined, size: 18.r)
                              .paddingOnly(right: 4.w),
                        ),
                        Visibility(
                          visible: item.type == MessageType.call,
                          child: Icon(Icons.call_outlined, size: 18.r)
                              .paddingOnly(right: 4.w),
                        ),
                        Flexible(
                          child: Text(
                            item.lastMessage ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: item.unreadCount > 0
                        ? CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text(
                              item.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      final id = store.currentUid;

                      if (id == null) return;

                      Get.toNamed(
                        AppRouteName.CHAT_ROOM_SCREEN,
                        arguments: ChatRoomArgument(
                          roomId: item.roomId,
                          currentUid: id,
                          targetUser: item.user,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: _buildBody(),
    );
  }
}
