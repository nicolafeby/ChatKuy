import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatAppbarWidget extends StatelessWidget implements PreferredSizeWidget {
  final ChatRoomStore store;
  final UserModel userData;
  final bool isTyping;
  const ChatAppbarWidget({
    super.key,
    required this.store,
    required this.userData,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          _buildAvatarSection(userData),
          12.horizontalSpace,
          _buildDisplayNameSections(userData, isTyping: isTyping),
        ],
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

  Widget _buildDisplayNameSections(UserModel user, {required bool isTyping}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: TextStyle(fontSize: 16.sp),
        ),
        4.verticalSpace,
        Text(
          isTyping
              ? 'Sedang mengetik ...'
              : user.isOnline == true
                  ? 'Online'
                  : (user.lastOnlineAt?.daysAndTime ?? ''),
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56);
}
