import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/core/widgets/skeleton.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/friend_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/friend/friend_list_store.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:chatkuy/ui/profile/user_profile_screen.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen>
    with AutomaticKeepAliveClientMixin, BaseLayout {
  final FriendListStore store = FriendListStore(
    friendRepository: getIt<FriendRepository>(),
    chatRepository: getIt<ChatRepository>(),
  );
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    store.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppbar() {
    if (_isSearching) return _buildSearchAppbar();

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor:
          isDarkModeOf(context) ? const Color(0xFF111B21) : Colors.white,
      surfaceTintColor:
          isDarkModeOf(context) ? const Color(0xFF111B21) : Colors.white,
      title: Text(
        AppTranslationKey.friends.tr,
        style: TextStyle(
          fontSize: 26.sp,
          fontWeight: FontWeight.w700,
          color: isDarkModeOf(context) ? Colors.white : AppColor.primaryColor,
        ),
      ),
      actions: [
        IconButton(
          tooltip: AppTranslationKey.search.tr,
          onPressed: _showSearch,
          icon: const Icon(Icons.search),
        ),
        IconButton(
          tooltip: AppTranslationKey.addFriend.tr,
          onPressed: () => Get.toNamed(AppRouteName.ADD_FRIEND_SCREEN),
          icon: const Icon(Icons.person_add_alt_1),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppbar() {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      leading: IconButton(
        tooltip: AppTranslationKey.closeSearch.tr,
        onPressed: _hideSearch,
        icon: const Icon(Icons.arrow_back),
      ),
      titleSpacing: 0,
      title: SizedBox(
        height: 40.h,
        child: TextField(
          controller: _searchController,
          autofocus: true,
          cursorHeight: 18.h,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 14.sp),
          onChanged: store.searchFriends,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDarkModeOf(context)
                ? const Color(0xFF202C33)
                : const Color(0xFFF0F2F5),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide.none,
            ),
            hintText: AppTranslationKey.search.tr,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
      actions: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();

            return IconButton(
              tooltip: AppTranslationKey.clearSearch.tr,
              onPressed: () {
                _searchController.clear();
                store.searchFriends('');
              },
              icon: const Icon(Icons.close),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Observer(
      builder: (context) {
        final colorScheme = colorSchemeOf(context);
        final isDark = isDarkModeOf(context);

        if (store.isLoading && store.friends.isEmpty) {
          return const ListTileSkeletonList(showSubtitleIcon: false);
        }

        if (store.errorMessage != null) {
          return Center(child: Text(store.errorMessage!));
        }

        return Column(
          children: [
            if (!_isSearching)
              ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                leading: CircleAvatar(
                  radius: 24.r,
                  backgroundColor: AppColor.primaryColor.withValues(
                    alpha: isDark ? 0.32 : 0.14,
                  ),
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: AppColor.primaryColor,
                    size: 24.r,
                  ),
                ),
                onTap: () =>
                    Get.toNamed(AppRouteName.FRIEND_REQUEST_LIST_SCREEN),
                title: Text(
                  AppTranslationKey.friendRequests.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 26.r,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.only(
                  top: _isSearching ? 8.h : 4.h,
                  bottom: 88.h,
                ),
                itemCount: store.friends.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 84.w,
                  color: colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.22 : 0.5,
                  ),
                ),
                itemBuilder: (context, index) {
                  final friend = store.friends[index];
                  final user = friend.user;

                  return ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    onTap: () => Get.toNamed(
                      AppRouteName.USER_PROFILE_SCREEN,
                      arguments: UserProfileArgument(targetUser: user),
                    ),
                    leading: ProfileAvatarWidget(
                      base64Image: user.photoUrl,
                      size: 52,
                    ),
                    title: Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      user.username != null ? '@${user.username}' : '',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: AppTranslationKey.chat.tr,
                      onPressed: () async {
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
                      icon: Icon(
                        Icons.chat,
                        color: colorScheme.onSurfaceVariant,
                        size: 22.r,
                      ),
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

  void _showSearch() {
    setState(() => _isSearching = true);
  }

  void _hideSearch() {
    setState(() => _isSearching = false);
    _searchController.clear();
    store.searchFriends('');
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
