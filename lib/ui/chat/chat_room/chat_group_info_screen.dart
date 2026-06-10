import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/data/models/friend_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/friend_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatGroupInfoArgument {
  const ChatGroupInfoArgument({
    required this.roomId,
    required this.currentUid,
  });

  final String roomId;
  final String currentUid;
}

class ChatGroupInfoScreen extends StatefulWidget {
  const ChatGroupInfoScreen({super.key});

  @override
  State<ChatGroupInfoScreen> createState() => _ChatGroupInfoScreenState();
}

class _ChatGroupInfoScreenState extends State<ChatGroupInfoScreen> {
  final ChatRoomStore store = ChatRoomStore(
    chatRepository: getIt<ChatRepository>(),
    userRepository: getIt<UserRepository>(),
  );
  final FriendRepository _friendRepository = getIt<FriendRepository>();
  final TextEditingController _groupNameController = TextEditingController();

  late final ChatGroupInfoArgument argument;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ChatGroupInfoArgument? ??
        const ChatGroupInfoArgument(roomId: '', currentUid: '');
    if (argument.roomId.isNotEmpty && argument.currentUid.isNotEmpty) {
      store.init(
        roomId: argument.roomId,
        currentUid: argument.currentUid,
        isGroup: true,
      );
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final room = store.room?.value;
        final members = store.groupMembers?.value ?? const <UserModel>[];
        final canManage = store.isCurrentUserGroupAdmin;
        final groupName =
            room?.name?.trim().isNotEmpty == true ? room!.name!.trim() : 'Grup';

        return Scaffold(
          appBar: AppBar(
            title: const SizedBox.shrink(),
            actions: [
              IconButton(
                tooltip: 'QR',
                onPressed: () {},
                icon: const Icon(Icons.qr_code_2),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit' && canManage) {
                    _showEditNameSheet(groupName);
                  }
                },
                itemBuilder: (_) => [
                  if (canManage)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit group name'),
                    ),
                ],
              ),
            ],
          ),
          body: ListView(
            children: [
              _GroupHeader(
                name: groupName,
                photoUrl: room?.photoUrl,
                memberCount: members.length,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
                child: Row(
                  children: [
                    _ActionTile(
                      icon: Icons.call_outlined,
                      label: 'Audio',
                      onTap: () {},
                    ),
                    12.horizontalSpace,
                    _ActionTile(
                      icon: Icons.videocam_outlined,
                      label: 'Video',
                      onTap: () {},
                    ),
                    12.horizontalSpace,
                    _ActionTile(
                      icon: Icons.link,
                      label: 'Invite',
                      onTap: canManage ? _showAddMembersSheet : null,
                    ),
                    12.horizontalSpace,
                    _ActionTile(
                      icon: Icons.search,
                      label: 'Search',
                      onTap: Navigator.of(context).pop,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _MembersSection(
                members: members,
                currentUid: argument.currentUid,
                adminUids: room?.admins ?? const [],
                canManage: canManage,
                onAddMembers: _showAddMembersSheet,
                onPromote: store.promoteGroupAdmin,
                onRemove: store.removeGroupMember,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Media, links, and docs'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '0',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditNameSheet(String groupName) async {
    _groupNameController.text = groupName;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20.w,
              16.h,
              20.w,
              MediaQuery.of(context).viewInsets.bottom + 20.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit group name',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                12.verticalSpace,
                TextField(
                  controller: _groupNameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Group name'),
                ),
                16.verticalSpace,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await store.updateGroupInfo(
                        name: _groupNameController.text,
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddMembersSheet() async {
    if (!store.isCurrentUserGroupAdmin) return;
    final existingUids = store.room?.value?.participants.toSet() ?? {};
    final selectedUids = <String>{};
    var isSaving = false;
    final friendsFuture = _friendRepository.getFriends();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> addMembers(List<FriendModel> friends) async {
              if (selectedUids.isEmpty || isSaving) return;
              setSheetState(() => isSaving = true);
              try {
                await store.inviteGroupMembers(selectedUids.toList());
                if (context.mounted) Navigator.of(context).pop();
              } finally {
                if (context.mounted) {
                  setSheetState(() => isSaving = false);
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                child: FutureBuilder<List<FriendModel>>(
                  future: friendsFuture,
                  builder: (context, snapshot) {
                    final friends = (snapshot.data ?? const <FriendModel>[])
                        .where((friend) {
                      final uid = friend.user.id.isNotEmpty
                          ? friend.user.id
                          : friend.uid;
                      return !existingUids.contains(uid);
                    }).toList();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add members',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        12.verticalSpace,
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator())
                        else if (friends.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('No friends available to add.'),
                          )
                        else
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: friends.length,
                              itemBuilder: (context, index) {
                                final friend = friends[index];
                                final user = friend.user;
                                final uid =
                                    user.id.isNotEmpty ? user.id : friend.uid;
                                return CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: selectedUids.contains(uid),
                                  title: Text(user.name),
                                  subtitle: Text(user.username ?? user.email),
                                  onChanged: (value) {
                                    setSheetState(() {
                                      if (value == true) {
                                        selectedUids.add(uid);
                                      } else {
                                        selectedUids.remove(uid);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        12.verticalSpace,
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: selectedUids.isEmpty || isSaving
                                ? null
                                : () => addMembers(friends),
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Add members'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.name,
    required this.photoUrl,
    required this.memberCount,
  });

  final String name;
  final String? photoUrl;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
      child: Column(
        children: [
          ProfileAvatarWidget(base64Image: photoUrl, size: 150),
          20.verticalSpace,
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          6.verticalSpace,
          Text.rich(
            TextSpan(
              text: 'Group · ',
              children: [
                TextSpan(
                  text: '$memberCount members',
                  style: const TextStyle(color: AppColor.primaryColor),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).hintColor,
            ),
          ),
          22.verticalSpace,
          Text(
            'Add group description',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColor.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 86.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColor.primaryColor, size: 26.r),
              8.verticalSpace,
              Text(
                label,
                style: TextStyle(fontSize: 13.sp),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.members,
    required this.currentUid,
    required this.adminUids,
    required this.canManage,
    required this.onAddMembers,
    required this.onPromote,
    required this.onRemove,
  });

  final List<UserModel> members;
  final String currentUid;
  final List<String> adminUids;
  final bool canManage;
  final VoidCallback onAddMembers;
  final Future<void> Function(String memberUid) onPromote;
  final Future<void> Function(String memberUid) onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${members.length} members',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.search, color: Theme.of(context).hintColor),
              ],
            ),
          ),
          10.verticalSpace,
          if (canManage)
            ListTile(
              leading: CircleAvatar(
                radius: 24.r,
                backgroundColor: AppColor.primaryColor,
                child: const Icon(Icons.group_add, color: Colors.white),
              ),
              title: const Text('Add members'),
              onTap: onAddMembers,
            ),
          ...members.map((member) {
            final isAdmin = adminUids.contains(member.id);
            final isCurrentUser = member.id == currentUid;

            return ListTile(
              leading:
                  ProfileAvatarWidget(base64Image: member.photoUrl, size: 48),
              title: Text(isCurrentUser ? 'You' : member.name),
              subtitle: isCurrentUser
                  ? const Text(
                      'Add member tag',
                      style: TextStyle(color: AppColor.primaryColor),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdmin)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primaryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Group Admin',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColor.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (canManage && !isCurrentUser)
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'admin') await onPromote(member.id);
                        if (value == 'remove') await onRemove(member.id);
                      },
                      itemBuilder: (_) => [
                        if (!isAdmin)
                          const PopupMenuItem(
                            value: 'admin',
                            child: Text('Jadikan admin'),
                          ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Keluarkan member'),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 20.w, top: 4.h),
              child: TextButton(
                onPressed: () {},
                child: const Text('View member changes'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
