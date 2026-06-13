import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/core/widgets/skeleton.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_user_item_model.dart';
import 'package:chatkuy/data/repositories/chat_user_list_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/chat/chat_list/chat_user_list_store.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:chatkuy/ui/chat/chat_list/widget/chat_list_search.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    super.key,
    this.archivedOnly = false,
  });

  final bool archivedOnly;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with BaseLayout {
  ChatUserListStore store = ChatUserListStore(
    repository: getIt<ChatUserListRepository>(),
  );
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedRoomIds = {};
  bool _isResolvingChatUsers = true;
  bool _canPopRoute = false;

  bool get _isSelectionMode => _selectedRoomIds.isNotEmpty;
  bool get _showArchivedChats => widget.archivedOnly;

  @override
  void initState() {
    super.initState();
    _watchInitialChatUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    store.dispose();
    super.dispose();
  }

  Future<void> _watchInitialChatUsers() async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ??
          await auth.idTokenChanges().first.timeout(
                const Duration(seconds: 2),
                onTimeout: () => null,
              );
      final currentUid =
          user?.uid ?? await getIt<SecureStorageRepository>().getUserId();

      if (currentUid != null) {
        store.watchChatUsers(currentUid);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingChatUsers = false;
        });
      }
    }
  }

  PreferredSizeWidget _buildAppbar() {
    if (_isSelectionMode) {
      return _buildSelectionAppbar();
    }

    return AppBar(
      automaticallyImplyLeading: widget.archivedOnly,
      backgroundColor:
          isDarkModeOf(context) ? const Color(0xFF111B21) : Colors.white,
      surfaceTintColor:
          isDarkModeOf(context) ? const Color(0xFF111B21) : Colors.white,
      leading: _showArchivedChats
          ? IconButton(
              tooltip: AppTranslationKey.chats.tr,
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back),
            )
          : null,
      title: Text(
        _showArchivedChats
            ? AppTranslationKey.archivedChats.tr
            : AppTranslationKey.chats.tr,
        style: TextStyle(
          fontSize: 26.sp,
          fontWeight: FontWeight.w700,
          color: _showArchivedChats
              ? Theme.of(context).colorScheme.onSurface
              : isDarkModeOf(context)
                  ? Colors.white
                  : AppColor.primaryColor,
        ),
      ),
      actions: _showArchivedChats
          ? null
          : [
              IconButton(
                tooltip: 'New group',
                onPressed: _openNewGroupPicker,
                icon: const Icon(Icons.group_add_outlined),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'new_group') {
                    _openNewGroupPicker();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'new_group',
                    child: Text('New group'),
                  ),
                  PopupMenuItem(
                    value: 'new_community',
                    child: Text('New community'),
                  ),
                  PopupMenuItem(
                    value: 'broadcast',
                    child: Text('Broadcast lists'),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                ],
              ),
            ],
    );
  }

  PreferredSizeWidget _buildSelectionAppbar() {
    final selectedItems = _selectedItems();
    final shouldUnmute =
        selectedItems.isNotEmpty && selectedItems.every((item) => item.isMuted);

    return AppBar(
      leading: IconButton(
        tooltip: AppTranslationKey.cancel.tr,
        onPressed: _clearSelection,
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(
        '${_selectedRoomIds.length}',
        style: TextStyle(fontSize: 24.sp),
      ),
      actions: [
        IconButton(
          tooltip: shouldUnmute
              ? AppTranslationKey.unmuteNotifications.tr
              : AppTranslationKey.muteNotifications.tr,
          onPressed: shouldUnmute ? _unmuteSelectedChats : _muteSelectedChats,
          icon: Icon(
            shouldUnmute
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
          ),
        ),
        IconButton(
          tooltip: _showArchivedChats
              ? AppTranslationKey.unarchive.tr
              : AppTranslationKey.archive.tr,
          onPressed: _showArchivedChats
              ? _unarchiveSelectedChats
              : _archiveSelectedChats,
          icon: Icon(_showArchivedChats
              ? Icons.unarchive_outlined
              : Icons.archive_outlined),
        ),
        IconButton(
          tooltip: AppTranslationKey.delete.tr,
          onPressed: _deleteSelectedChats,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final isDark = isDarkModeOf(context);
    return Column(
      children: [
        ChatListSearchWidget(
          controller: _searchController,
          onChanged: store.setSearchQuery,
          onClear: () {
            _searchController.clear();
            store.clearSearch();
          },
        ).paddingSymmetric(horizontal: 20.r).paddingOnly(bottom: 8.h),

        /// REALTIME CHAT LIST
        Expanded(
          child: Observer(
            builder: (_) {
              if (_isResolvingChatUsers || store.isLoading) {
                return const ListTileSkeletonList();
              }

              if (store.errorMessage != null) {
                return Center(
                  child: Text(store.errorMessage!),
                );
              }

              final isSearching = store.searchQuery.trim().isNotEmpty;

              if (store.chatUsers.isEmpty) {
                _selectedRoomIds.clear();
                return Center(
                  child: Text(AppTranslationKey.noChats.tr),
                );
              }

              if (isSearching && !_showArchivedChats) {
                final searchResults = store.searchResults;
                if (searchResults.isEmpty) {
                  return Center(
                    child: Text(AppTranslationKey.messageNotFound.tr),
                  );
                }

                return ListView.separated(
                  itemCount: searchResults.length,
                  separatorBuilder: (_, __) => SizedBox(height: 2.h),
                  itemBuilder: (_, index) {
                    final result = searchResults[index];
                    final item = result.item;
                    final user = item.user;

                    return ListTile(
                      leading: ProfileAvatarWidget(
                        base64Image: user.photoUrl,
                        size: 48,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: _buildHighlightedText(
                              text: user.name,
                              query: store.searchQuery,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            (result.message?.createdAtClient ??
                                        item.lastMessageAt)
                                    ?.hhmm ??
                                '',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark ? null : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Visibility(
                            visible: result.message?.type == MessageType.image,
                            child: Icon(Icons.image_outlined, size: 18.r)
                                .paddingOnly(right: 4.w),
                          ),
                          Visibility(
                            visible: result.message?.type == MessageType.video,
                            child: Icon(Icons.videocam_outlined, size: 18.r)
                                .paddingOnly(right: 4.w),
                          ),
                          Visibility(
                            visible: result.message?.type == MessageType.call,
                            child: Icon(Icons.call_outlined, size: 18.r)
                                .paddingOnly(right: 4.w),
                          ),
                          Visibility(
                            visible: result.message?.type == MessageType.file,
                            child: Icon(Icons.description_outlined, size: 18.r)
                                .paddingOnly(right: 4.w),
                          ),
                          Visibility(
                            visible:
                                result.message?.type == MessageType.contact,
                            child: Icon(Icons.person_outline, size: 18.r)
                                .paddingOnly(right: 4.w),
                          ),
                          Flexible(
                            child: _buildHighlightedText(
                              text: result.previewText,
                              query: store.searchQuery,
                              style: TextStyle(
                                color: isDark ? null : Colors.black54,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _openChatRoom(
                        item,
                        targetMessageId: result.message?.id,
                        initialHighlightQuery: store.searchQuery,
                      ),
                    );
                  },
                );
              }

              final chatUsers = _currentChatUsers(isSearching: isSearching);
              _selectedRoomIds.removeWhere(
                (roomId) => !chatUsers.any((item) => item.roomId == roomId),
              );
              final showArchivedEntry = !_showArchivedChats &&
                  !isSearching &&
                  store.archivedChatUsers.isNotEmpty;
              if (chatUsers.isEmpty) {
                if (showArchivedEntry) {
                  return ListView(
                    children: [
                      _buildArchivedEntry(),
                    ],
                  );
                }

                return Center(
                  child: Text(
                    _showArchivedChats
                        ? AppTranslationKey.noArchivedChats.tr
                        : AppTranslationKey.chatNotFound.tr,
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.only(bottom: 88.h),
                itemCount: chatUsers.length + (showArchivedEntry ? 1 : 0),
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 84.w,
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: isDark ? 0.22 : 0.5),
                ),
                itemBuilder: (_, index) {
                  if (showArchivedEntry && index == 0) {
                    return _buildArchivedEntry();
                  }

                  final itemIndex = showArchivedEntry ? index - 1 : index;
                  final item = chatUsers[itemIndex];
                  final user = item.user;
                  final isSelected = _selectedRoomIds.contains(item.roomId);

                  final tile = ListTile(
                    minVerticalPadding: 10.h,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                    tileColor: isSelected
                        ? AppColor.primaryColor.withValues(
                            alpha: isDark ? 0.24 : 0.14,
                          )
                        : null,
                    leading: _buildSelectableAvatar(
                      image: user.photoUrl,
                      isSelected: isSelected,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: _buildHighlightedText(
                            text: user.name,
                            query: store.searchQuery,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: item.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          item.lastMessageAt?.hhmm ?? '',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: item.unreadCount > 0
                                ? AppColor.accentColor
                                : isDark
                                    ? Colors.white54
                                    : Colors.black54,
                            fontWeight: item.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        if (_shouldShowStatus(item))
                          _buildStatusIcon(item).paddingOnly(right: 4.w),
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
                        Visibility(
                          visible: item.type == MessageType.file,
                          child: Icon(Icons.description_outlined, size: 18.r)
                              .paddingOnly(right: 4.w),
                        ),
                        Visibility(
                          visible: item.type == MessageType.contact,
                          child: Icon(Icons.person_outline, size: 18.r)
                              .paddingOnly(right: 4.w),
                        ),
                        Flexible(
                          child: _buildHighlightedText(
                            text: _previewText(
                              item: item,
                              isSearching: isSearching,
                            ),
                            query: store.searchQuery,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 14.sp,
                              fontWeight: item.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: _buildChatTrailing(item, isDark: isDark),
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleChatSelection(item);
                        return;
                      }

                      _openChatRoom(item);
                    },
                    onLongPress: () => _toggleChatSelection(item),
                  );

                  if (_isSelectionMode) {
                    return tile;
                  }

                  return Dismissible(
                    key: ValueKey('chat-${item.roomId}-${item.isArchived}'),
                    direction: DismissDirection.endToStart,
                    background:
                        _buildArchiveBackground(isArchived: _showArchivedChats),
                    onDismissed: (_) => _showArchivedChats
                        ? _performUnarchiveChats([item])
                        : _performArchiveChats([item]),
                    child: tile,
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
    return PopScope(
      canPop: _canPopRoute,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelectionMode) {
          _clearSelection();
          return;
        }

        setState(() {
          _canPopRoute = true;
        });
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: _buildAppbar(),
        body: _buildBody(),
        floatingActionButton: _showArchivedChats
            ? null
            : FloatingActionButton(
                heroTag: 'chat-list-new-chat',
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.white,
                onPressed: () => Get.toNamed(AppRouteName.ADD_FRIEND_SCREEN),
                child: const Icon(Icons.chat),
              ),
      ),
    );
  }

  void _openChatRoom(
    ChatUserItemModel item, {
    String? targetMessageId,
    String? initialHighlightQuery,
  }) {
    final id = store.currentUid;

    if (id == null) return;

    Get.toNamed(
      AppRouteName.CHAT_ROOM_SCREEN,
      arguments: ChatRoomArgument(
        roomId: item.roomId,
        currentUid: id,
        targetUser: item.user,
        isGroup: item.isGroup,
        targetMessageId: targetMessageId,
        initialHighlightQuery: initialHighlightQuery,
      ),
    );
  }

  void _openNewGroupPicker() {
    final currentUid = store.currentUid;
    if (currentUid == null || currentUid.isEmpty) return;

    Get.toNamed(
      AppRouteName.CHAT_GROUP_PICKER_SCREEN,
      arguments: ChatGroupPickerArgument(currentUid: currentUid),
    );
  }

  List<ChatUserItemModel> _currentChatUsers({required bool isSearching}) {
    if (!_showArchivedChats) return store.filteredChatUsers;

    final query = store.searchQuery.trim().toLowerCase();
    if (!isSearching) return store.archivedChatUsers;

    return store.archivedChatUsers.where((item) {
      final name = item.user.name.toLowerCase();
      final email = item.user.email.toLowerCase();
      final lastMessage = item.lastMessage?.toLowerCase() ?? '';
      return name.contains(query) ||
          email.contains(query) ||
          lastMessage.contains(query);
    }).toList();
  }

  Widget _buildArchivedEntry() {
    final isDark = isDarkModeOf(context);
    final unreadCount = store.archivedChatUsers.fold<int>(
      0,
      (total, item) => total + item.unreadCount,
    );

    return ListTile(
      leading: SizedBox(
        width: 52.r,
        height: 52.r,
        child: Icon(Icons.archive_outlined, size: 24.r),
      ),
      title: Text(
        AppTranslationKey.archivedChats.tr,
        style: TextStyle(
          fontSize: 16.sp,
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: unreadCount > 0
          ? CircleAvatar(
              radius: 10,
              backgroundColor: AppColor.accentColor,
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Color(0xFF063D34),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      onTap: () {
        Get.toNamed(AppRouteName.CHAT_ARCHIVE_SCREEN);
      },
    );
  }

  String _previewText({
    required ChatUserItemModel item,
    required bool isSearching,
  }) {
    if (!isSearching) return item.lastMessage ?? '';

    final matchedMessage = store.matchedMessageText(item);
    if (matchedMessage != null && matchedMessage.isNotEmpty) {
      return matchedMessage;
    }

    if (item.lastMessage != null && item.lastMessage!.isNotEmpty) {
      return item.lastMessage!;
    }

    return item.user.email;
  }

  bool _shouldShowStatus(ChatUserItemModel item) {
    return item.lastSenderId == store.currentUid &&
        item.lastMessageStatus != null;
  }

  Widget? _buildChatTrailing(
    ChatUserItemModel item, {
    required bool isDark,
  }) {
    if (item.unreadCount <= 0 && !item.isMuted) return null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.unreadCount > 0)
          CircleAvatar(
            radius: 10.r,
            backgroundColor: AppColor.accentColor,
            child: Text(
              item.unreadCount.toString(),
              style: const TextStyle(
                color: Color(0xFF063D34),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (item.isMuted) ...[
          if (item.unreadCount > 0) 4.verticalSpace,
          Icon(
            Icons.notifications_off_outlined,
            size: 16.r,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ],
      ],
    );
  }

  Widget _buildSelectableAvatar({
    required String? image,
    required bool isSelected,
  }) {
    return SizedBox(
      width: 52.r,
      height: 52.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: ProfileAvatarWidget(
              base64Image: image,
              size: 48,
            ),
          ),
          if (isSelected)
            Positioned(
              right: -1.r,
              bottom: 1.r,
              child: Container(
                width: 22.r,
                height: 22.r,
                decoration: BoxDecoration(
                  color: AppColor.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2.r,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 15.r,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArchiveBackground({required bool isArchived}) {
    return Container(
      color: isArchived ? AppColor.primaryColor : AppColor.primaryDarkColor,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Icon(
        isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
        color: Colors.white,
        size: 24.r,
      ),
    );
  }

  Future<bool> _confirmDeleteChats(List<ChatUserItemModel> items) async {
    if (items.isEmpty) return false;

    final isSingle = items.length == 1;
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                isSingle
                    ? AppTranslationKey.deleteChatTitle.trParams({
                        'name': items.first.user.name,
                      })
                    : AppTranslationKey.deleteChatsTitle.trParams({
                        'count': '${items.length}',
                      }),
              ),
              content: Text(AppTranslationKey.deleteChatContent.tr),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppTranslationKey.cancel.tr),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    AppTranslationKey.delete.tr,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _deleteSelectedChats() async {
    final selectedItems = _selectedItems();
    if (selectedItems.isEmpty) {
      _clearSelection();
      return;
    }

    if (await _confirmDeleteChats(selectedItems)) {
      await _performDeleteChats(selectedItems);
    }
  }

  Future<void> _archiveSelectedChats() async {
    final selectedItems = _selectedItems();
    if (selectedItems.isEmpty) {
      _clearSelection();
      return;
    }

    await _performArchiveChats(selectedItems);
  }

  Future<void> _unarchiveSelectedChats() async {
    final selectedItems = _selectedItems();
    if (selectedItems.isEmpty) {
      _clearSelection();
      return;
    }

    await _performUnarchiveChats(selectedItems);
  }

  Future<void> _muteSelectedChats() async {
    final selectedItems = _selectedItems();
    if (selectedItems.isEmpty) {
      _clearSelection();
      return;
    }

    final mutedUntil = await _showMuteOptions();
    if (mutedUntil == null) return;

    await _performMuteChats(selectedItems, mutedUntil);
  }

  Future<void> _unmuteSelectedChats() async {
    final selectedItems = _selectedItems();
    if (selectedItems.isEmpty) {
      _clearSelection();
      return;
    }

    await _performUnmuteChats(selectedItems);
  }

  Future<DateTime?> _showMuteOptions() {
    return showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final now = DateTime.now();

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_off_outlined),
                title: Text(AppTranslationKey.muteFor8Hours.tr),
                onTap: () => Navigator.of(context).pop(
                  now.add(const Duration(hours: 8)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off_outlined),
                title: Text(AppTranslationKey.muteFor1Week.tr),
                onTap: () => Navigator.of(context).pop(
                  now.add(const Duration(days: 7)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off_outlined),
                title: Text(AppTranslationKey.muteAlways.tr),
                onTap: () => Navigator.of(context).pop(
                  now.add(const Duration(days: 36500)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<ChatUserItemModel> _selectedItems() {
    return store.chatUsers
        .where((item) => _selectedRoomIds.contains(item.roomId))
        .toList();
  }

  Future<void> _performDeleteChats(List<ChatUserItemModel> items) async {
    try {
      await store.deleteChats(items);
      if (mounted) {
        _clearSelection(force: true);
      }
    } catch (_) {
      if (mounted) {
        Get.snackbar(
          AppTranslationKey.deleteChatFailed.tr,
          items.length == 1 ? items.first.user.name : '${items.length}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _performArchiveChats(List<ChatUserItemModel> items) async {
    try {
      await store.archiveChats(items);
      if (mounted) {
        _clearSelection(force: true);
      }
    } catch (_) {
      if (mounted) {
        Get.snackbar(
          AppTranslationKey.archiveChatFailed.tr,
          items.length == 1 ? items.first.user.name : '${items.length}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _performUnarchiveChats(List<ChatUserItemModel> items) async {
    try {
      await store.unarchiveChats(items);
      if (mounted) {
        _clearSelection(force: true);
      }
    } catch (_) {
      if (mounted) {
        Get.snackbar(
          AppTranslationKey.unarchiveChatFailed.tr,
          items.length == 1 ? items.first.user.name : '${items.length}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _performMuteChats(
    List<ChatUserItemModel> items,
    DateTime mutedUntil,
  ) async {
    try {
      await store.muteChatsUntil(items, mutedUntil);
      if (mounted) {
        _clearSelection(force: true);
        Get.snackbar(
          AppTranslationKey.notifications.tr,
          AppTranslationKey.mutedNotifications.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (mounted) {
        Get.snackbar(
          AppTranslationKey.notifications.tr,
          AppTranslationKey.somethingWentWrong.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _performUnmuteChats(List<ChatUserItemModel> items) async {
    try {
      await store.unmuteChats(items);
      if (mounted) {
        _clearSelection(force: true);
        Get.snackbar(
          AppTranslationKey.notifications.tr,
          AppTranslationKey.notificationsUnmuted.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (mounted) {
        Get.snackbar(
          AppTranslationKey.notifications.tr,
          AppTranslationKey.somethingWentWrong.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _toggleChatSelection(ChatUserItemModel item) {
    setState(() {
      if (_selectedRoomIds.contains(item.roomId)) {
        _selectedRoomIds.remove(item.roomId);
      } else {
        _selectedRoomIds.add(item.roomId);
      }
    });
  }

  void _clearSelection({bool force = false}) {
    if (_selectedRoomIds.isEmpty && !force) return;
    setState(_selectedRoomIds.clear);
  }

  Widget _buildStatusIcon(ChatUserItemModel item) {
    if (item.lastMessageStatus == MessageStatus.failed) {
      return Icon(Icons.error, size: 16.r, color: Colors.redAccent);
    }

    if (item.lastMessageStatus == MessageStatus.pending) {
      return Icon(Icons.access_time, size: 16.r, color: Colors.grey);
    }

    if (item.lastMessageReadBy.isNotEmpty) {
      return Icon(Icons.done_all, size: 16.r, color: Colors.blueAccent);
    }

    if (item.lastMessageDeliveredTo.isNotEmpty) {
      return Icon(Icons.done_all, size: 16.r, color: Colors.grey);
    }

    return Icon(Icons.check, size: 16.r, color: Colors.grey);
  }

  Widget _buildHighlightedText({
    required String text,
    required String query,
    required TextStyle style,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty ||
        text.toLowerCase().contains(normalizedQuery) == false) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    var start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(normalizedQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + normalizedQuery.length),
          style: const TextStyle(
            color: Colors.black,
            backgroundColor: Colors.amber,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + normalizedQuery.length;
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: spans,
      ),
    );
  }
}
