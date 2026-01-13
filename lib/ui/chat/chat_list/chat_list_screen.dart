import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/data/repositories/chat_user_list_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/chat/chat_list/chat_user_list_store.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:chatkuy/ui/chat/chat_list/widget/chat_item_widget.dart';
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

class _ChatListScreenState extends State<ChatListScreen> {
  ChatUserListStore store = ChatUserListStore(
    repository: getIt<ChatUserListRepository>(),
  );

  @override
  void initState() {
    super.initState();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    /// ambil uid dari auth / session kamu
    /// contoh (sesuaikan dengan project kamu):

    if (currentUid == null) return;
    store.watchChatUsers(currentUid);
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppbar() {
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
        ).paddingOnly(right: 16.r)
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        ChatListSearchWidget().paddingSymmetric(horizontal: 20.r).paddingOnly(bottom: 8.h),

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
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final item = store.chatUsers[index];
                  final user = item.user;

                  // return ChatItemWidget(
                  //   onTap: () {
                  //     final id = store.currentUid;

                  //     if (id == null) return;

                  //     Get.toNamed(
                  //       AppRouteName.CHAT_ROOM_SCREEN,
                  //       arguments: ChatRoomArgument(
                  //         roomId: item.roomId,
                  //         currentUid: id,
                  //         targetUser: item.user,
                  //       ),
                  //     );
                  //   },
                  //   user: item,
                  // );

                  return ListTile(
                    leading: SizedBox(
                      height: 48.r,
                      width: 48.r,
                      child: CircleAvatar(
                        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                        child: user.photoUrl == null ? Text(user.name[0].toUpperCase()) : null,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(user.name),
                        Text(
                          item.lastMessageAt?.hhmm ?? '',
                          style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      item.lastMessage ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
