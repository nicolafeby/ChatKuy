import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/friend_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/friend/friend_list_store.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> with AutomaticKeepAliveClientMixin {
  final FriendListStore store = FriendListStore(
    friendRepository: getIt<FriendRepository>(),
    chatRepository: getIt<ChatRepository>(),
  );

  @override
  bool get wantKeepAlive => true;

  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Teman',
        style: TextStyle(fontSize: 28.sp),
      ),
      actions: [
        GestureDetector(
          onTap: () {},
          child: const Icon(Icons.search),
        ),
        16.horizontalSpace,
        GestureDetector(
          onTap: () => Get.toNamed(AppRouteName.ADD_FRIEND_SCREEN),
          child: Icon(Icons.person_add).paddingOnly(right: 16.r),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Observer(
      builder: (_) {
        if (store.isLoading && store.friends.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (store.errorMessage != null) {
          return Center(child: Text(store.errorMessage!));
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: EdgeInsetsDirectional.symmetric(horizontal: 20.w),
              // padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black54), borderRadius: BorderRadius.circular(8.r)),
              child: ListTile(
                onTap: () => Get.toNamed(AppRouteName.FRIEND_REQUEST_LIST_SCREEN),
                title: Text(
                  'Permintaan Pertemanan',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16.sp, color: Colors.black87),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_outlined,
                  size: 18.r,
                  color: Colors.black54,
                ),
              ),
              // child: Text(
              //   'Permintaan Pertemanan',
              //   textAlign: TextAlign.left,
              //   style: TextStyle(fontSize: 16.sp, color: Colors.black87),
              // ),
            ).paddingOnly(top: 8.h),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                itemCount: store.friends.length,
                separatorBuilder: (_, __) => 12.verticalSpace,
                itemBuilder: (context, index) {
                  final friend = store.friends[index];
                  final user = friend.user;

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24.r,
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      user.username != null ? '@${user.username}' : '',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: InkWell(
                      onTap: () async {
                        await store.openChat(targetUid: friend.uid);

                        final roomId = store.roomId;
                        final currentUid = store.currentUid;

                        if (roomId == null || currentUid == null) return;

                        Get.toNamed(
                          AppRouteName.CHAT_ROOM_SCREEN,
                          arguments: ChatRoomArgument(
                            roomId: roomId,
                            currentUid: currentUid,
                            targetUser: user,
                          ),
                        );
                      },
                      child: const Icon(Icons.chat),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: _buildAppbar(),
      body: _buildBody(),
    );
  }
}
