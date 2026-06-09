import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatAppbarWidget extends StatelessWidget implements PreferredSizeWidget {
  final ChatRoomStore store;
  final UserModel userData;
  final bool isTyping;
  final VoidCallback? onCallTap;
  final VoidCallback? onVideoCallTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  final bool canViewPresence;
  const ChatAppbarWidget({
    super.key,
    required this.store,
    required this.userData,
    required this.isTyping,
    this.onCallTap,
    this.onVideoCallTap,
    this.onSearchTap,
    this.onProfileTap,
    this.canViewPresence = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      title: InkWell(
        onTap: onProfileTap,
        child: Row(
          children: [
            _buildAvatarSection(userData),
            12.horizontalSpace,
            Expanded(
              child: _buildDisplayNameSections(
                userData,
                isTyping: isTyping,
                canViewPresence: canViewPresence,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: onSearchTap,
          icon: const Icon(Icons.search),
          tooltip: AppTranslationKey.text(AppTranslationKey.searchMessages),
        ),
        IconButton(
          onPressed: onVideoCallTap,
          icon: const Icon(Icons.videocam),
          tooltip: AppTranslationKey.text(AppTranslationKey.videoCall),
        ),
        IconButton(
          onPressed: onCallTap,
          icon: const Icon(Icons.call),
          tooltip: AppTranslationKey.text(AppTranslationKey.voiceCall),
        ),
      ],
      elevation: 2,
    );
  }

  Widget _buildAvatarSection(UserModel user) =>
      ProfileAvatarWidget(base64Image: user.photoUrl, size: 36);

  Widget _buildDisplayNameSections(
    UserModel user, {
    required bool isTyping,
    required bool canViewPresence,
  }) {
    final statusText = canViewPresence
        ? (isTyping
            ? AppTranslationKey.text(AppTranslationKey.typing)
            : user.isOnline == true
                ? AppTranslationKey.text(AppTranslationKey.online)
                : (user.lastOnlineAt?.daysAndTime ?? ''))
        : AppTranslationKey.text(AppTranslationKey.hiddenOnlineStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: TextStyle(fontSize: 16.sp),
        ),
        4.verticalSpace,
        Text(
          statusText,
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
