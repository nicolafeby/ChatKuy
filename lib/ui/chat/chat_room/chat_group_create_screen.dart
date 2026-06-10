import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/data/models/friend_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/friend_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatGroupPickerArgument {
  const ChatGroupPickerArgument({required this.currentUid});

  final String currentUid;
}

class ChatGroupCreateArgument {
  const ChatGroupCreateArgument({
    required this.currentUid,
    required this.members,
  });

  final String currentUid;
  final List<UserModel> members;
}

class ChatGroupPickerScreen extends StatefulWidget {
  const ChatGroupPickerScreen({super.key});

  @override
  State<ChatGroupPickerScreen> createState() => _ChatGroupPickerScreenState();
}

class _ChatGroupPickerScreenState extends State<ChatGroupPickerScreen> {
  final FriendRepository _friendRepository = getIt<FriendRepository>();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUids = {};
  late final ChatGroupPickerArgument argument;
  late final Future<List<FriendModel>> _friendsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ChatGroupPickerArgument? ?? const ChatGroupPickerArgument(currentUid: '');
    _friendsFuture = _friendRepository.getFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _SearchHeader(
          controller: _searchController,
          hintText: 'Search name or number...',
          onChanged: (value) {
            setState(() => _query = value);
          },
        ),
      ),
      body: FutureBuilder<List<FriendModel>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = _filteredFriends(snapshot.data ?? const []);
          if (friends.isEmpty) {
            return const Center(child: Text('No contacts found'));
          }

          return ListView.separated(
            padding: EdgeInsets.only(bottom: 96.h),
            itemCount: friends.length + 1,
            separatorBuilder: (_, index) => index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 12.h),
                  child: Text(
                    'Frequently contacted',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              final friend = friends[index - 1];
              final user = _friendUser(friend);
              final selected = _selectedUids.contains(user.id);

              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
                leading: ProfileAvatarWidget(
                  base64Image: user.photoUrl,
                  size: 52,
                ),
                title: Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: user.username == null ? null : Text(user.username!),
                trailing: _SelectionCircle(selected: selected),
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedUids.remove(user.id);
                    } else {
                      _selectedUids.add(user.id);
                    }
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<FriendModel>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          final selectedMembers = (snapshot.data ?? const <FriendModel>[])
              .map(_friendUser)
              .where((user) => _selectedUids.contains(user.id))
              .toList();

          return FloatingActionButton(
            heroTag: 'group-picker-next',
            onPressed: selectedMembers.isEmpty
                ? null
                : () => Get.toNamed(
                      AppRouteName.CHAT_GROUP_CREATE_SCREEN,
                      arguments: ChatGroupCreateArgument(
                        currentUid: argument.currentUid,
                        members: selectedMembers,
                      ),
                    ),
            backgroundColor: selectedMembers.isEmpty ? Theme.of(context).disabledColor : AppColor.primaryColor,
            child: const Icon(Icons.arrow_forward),
          );
        },
      ),
    );
  }

  List<FriendModel> _filteredFriends(List<FriendModel> friends) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return friends;

    return friends.where((friend) {
      final user = friend.user;
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.username?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  UserModel _friendUser(FriendModel friend) {
    final user = friend.user;
    if (user.id.isNotEmpty) return user;
    return user.copyWith(id: friend.uid);
  }
}

class ChatGroupCreateScreen extends StatefulWidget {
  const ChatGroupCreateScreen({super.key});

  @override
  State<ChatGroupCreateScreen> createState() => _ChatGroupCreateScreenState();
}

class _ChatGroupCreateScreenState extends State<ChatGroupCreateScreen> {
  final ChatRepository _chatRepository = getIt<ChatRepository>();
  final TextEditingController _nameController = TextEditingController();
  late final ChatGroupCreateArgument argument;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ChatGroupCreateArgument? ?? const ChatGroupCreateArgument(currentUid: '', members: []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New group'),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 110.h),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32.r,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 28.r,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                16.horizontalSpace,
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Group name (optional)',
                      suffixIcon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Disappearing messages'),
            subtitle: const Text('Off'),
            trailing: Icon(
              Icons.timer_outlined,
              color: Theme.of(context).hintColor,
            ),
          ),
          ListTile(
            title: const Text('Group permissions'),
            trailing: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).hintColor,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 12.h),
            child: Text(
              'Members: ${argument.members.length}',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 118.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: argument.members.length,
              separatorBuilder: (_, __) => 16.horizontalSpace,
              itemBuilder: (context, index) {
                final member = argument.members[index];
                return SizedBox(
                  width: 76.w,
                  child: Column(
                    children: [
                      ProfileAvatarWidget(
                        base64Image: member.photoUrl,
                        size: 66,
                      ),
                      8.verticalSpace,
                      Text(
                        member.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'group-create-submit',
        backgroundColor: _isCreating ? Theme.of(context).disabledColor : AppColor.primaryColor,
        onPressed: _isCreating ? null : _createGroup,
        child: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
      ),
    );
  }

  Future<void> _createGroup() async {
    if (argument.currentUid.isEmpty || argument.members.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final roomName = _resolvedRoomName();
      final roomId = await _chatRepository.createGroupRoom(
        currentUid: argument.currentUid,
        name: roomName,
        memberUids: argument.members.map((member) => member.id).toList(),
      );

      if (!mounted) return;
      Get.offNamed(
        AppRouteName.CHAT_ROOM_SCREEN,
        arguments: ChatRoomArgument(
          roomId: roomId,
          currentUid: argument.currentUid,
          targetUser: UserModel(
            id: roomId,
            name: roomName,
            email: '',
            isEmailVerified: false,
            fcmToken: '',
            isOnlineStatusVisible: false,
          ),
          isGroup: true,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Tidak punya izin membuat grup. Pastikan Firestore rules sudah diperbarui.'
          : e.message ?? 'Gagal membuat grup';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat grup: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  String _resolvedRoomName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) return name;

    final memberNames = argument.members.map((member) => member.name).toList();
    if (memberNames.length <= 2) return memberNames.join(', ');
    return '${memberNames.take(2).join(', ')} +${memberNames.length - 2}';
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            autofocus: true,
            cursorHeight: 16.h,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              prefixIconColor: Colors.grey,
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      icon: Icon(Icons.close, size: 18.r),
                    ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(50.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(50.r),
              ),
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
          );
        },
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 28.r,
      height: 28.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColor.primaryColor : Colors.transparent,
        border: Border.all(
          color: selected ? AppColor.primaryColor : Theme.of(context).hintColor,
          width: 2,
        ),
      ),
      child: selected ? Icon(Icons.check, size: 18.r, color: Colors.white) : null,
    );
  }
}
