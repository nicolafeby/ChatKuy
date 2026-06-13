import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/constants/color.dart';
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
  final VoidCallback? onAddMembersTap;
  final VoidCallback? onGroupInfoTap;
  final VoidCallback? onGroupMediaTap;
  final VoidCallback? onMuteTap;
  final VoidCallback? onUnmuteTap;
  final bool canViewPresence;
  final bool isGroup;
  final bool isMuted;
  final String? subtitle;
  const ChatAppbarWidget({
    super.key,
    required this.store,
    required this.userData,
    required this.isTyping,
    this.onCallTap,
    this.onVideoCallTap,
    this.onSearchTap,
    this.onProfileTap,
    this.onAddMembersTap,
    this.onGroupInfoTap,
    this.onGroupMediaTap,
    this.onMuteTap,
    this.onUnmuteTap,
    this.canViewPresence = true,
    this.isGroup = false,
    this.isMuted = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.primaryDarkColor,
      foregroundColor: Colors.white,
      surfaceTintColor: AppColor.primaryDarkColor,
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
                titleColor: Colors.white,
                subtitleColor: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: onVideoCallTap,
          icon: const Icon(Icons.videocam),
          tooltip: AppTranslationKey.text(AppTranslationKey.videoCall),
        ),
        if (!isGroup)
          IconButton(
            onPressed: onCallTap,
            icon: const Icon(Icons.call),
            tooltip: AppTranslationKey.text(AppTranslationKey.voiceCall),
          ),
        _buildOverflowMenu(),
      ],
      elevation: 0,
    );
  }

  Widget _buildAvatarSection(UserModel user) =>
      ProfileAvatarWidget(base64Image: user.photoUrl, size: 36);

  Widget _buildDisplayNameSections(
    UserModel user, {
    required bool isTyping,
    required bool canViewPresence,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final statusText = subtitle ??
        (canViewPresence
            ? (isTyping
                ? AppTranslationKey.text(AppTranslationKey.typing)
                : user.isOnline == true
                    ? AppTranslationKey.text(AppTranslationKey.online)
                    : (user.lastOnlineAt?.daysAndTime ?? ''))
            : AppTranslationKey.text(AppTranslationKey.hiddenOnlineStatus));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16.sp,
            color: titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        4.verticalSpace,
        Text(
          statusText,
          style: TextStyle(
            fontSize: 11.sp,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56);

  Widget _buildOverflowMenu() {
    if (!isGroup) {
      return PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'search') onSearchTap?.call();
          if (value == 'mute') onMuteTap?.call();
          if (value == 'unmute') onUnmuteTap?.call();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'search',
            child:
                Text(AppTranslationKey.text(AppTranslationKey.searchMessages)),
          ),
          PopupMenuItem(
            value: isMuted ? 'unmute' : 'mute',
            child: Text(
              AppTranslationKey.text(
                isMuted
                    ? AppTranslationKey.unmuteNotifications
                    : AppTranslationKey.muteNotifications,
              ),
            ),
          ),
        ],
      );
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'add') onAddMembersTap?.call();
        if (value == 'info') {
          if (onGroupInfoTap != null) {
            onGroupInfoTap!.call();
          } else {
            onProfileTap?.call();
          }
        }
        if (value == 'media') onGroupMediaTap?.call();
        if (value == 'search') onSearchTap?.call();
        if (value == 'mute') onMuteTap?.call();
        if (value == 'unmute') onUnmuteTap?.call();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'add',
          child: Text(AppTranslationKey.text(AppTranslationKey.addMembers)),
        ),
        PopupMenuItem(
          value: 'info',
          child: Text(AppTranslationKey.text(AppTranslationKey.groupInfo)),
        ),
        PopupMenuItem(
          value: 'media',
          child: Text(AppTranslationKey.text(AppTranslationKey.groupMedia)),
        ),
        PopupMenuItem(
          value: 'search',
          child: Text(AppTranslationKey.text(AppTranslationKey.search)),
        ),
        PopupMenuItem(
          value: isMuted ? 'unmute' : 'mute',
          child: Text(
            AppTranslationKey.text(
              isMuted
                  ? AppTranslationKey.unmuteNotifications
                  : AppTranslationKey.muteNotifications,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'disappearing',
          child: Text(
            AppTranslationKey.text(AppTranslationKey.disappearingMessages),
          ),
        ),
        PopupMenuItem(
          value: 'theme',
          child: Text(AppTranslationKey.text(AppTranslationKey.chatTheme)),
        ),
        PopupMenuItem(
          value: 'more',
          child: Text(AppTranslationKey.text(AppTranslationKey.more)),
        ),
      ],
    );
  }
}
