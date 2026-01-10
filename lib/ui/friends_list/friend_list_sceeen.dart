import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/data/repositories/friend_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/friend/friend_list_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  FriendListStore store = FriendListStore(
    friendRepository: getIt<FriendRepository>(),
  );

  @override
  void initState() {
    super.initState();
    store.listenFriends();
  }

  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Teman',
        style: TextStyle(fontSize: 28.sp),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            Get.toNamed(AppRouteName.FRIEND_REQUEST_LIST_SCREEN);
          },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: Observer(
        builder: (_) => ListView.separated(
          itemCount: store.friends.length,
          separatorBuilder: (_, __) => 12.verticalSpace,
          itemBuilder: (context, index) {
            final friend = store.friends[index];

            return ListTile(
              leading: CircleAvatar(
                radius: 24.r,
                backgroundImage:
                    friend.photoUrl != null && friend.photoUrl!.isNotEmpty ? NetworkImage(friend.photoUrl!) : null,
                child: friend.photoUrl == null || friend.photoUrl!.isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text(
                friend.displayName?.isNotEmpty == true ? friend.displayName! : friend.username,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '@${friend.username}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey,
                ),
              ),
              onTap: () {
                // TODO: open chat / profile
              },
            );
          },
        ),
      ),
    );
  }
}
