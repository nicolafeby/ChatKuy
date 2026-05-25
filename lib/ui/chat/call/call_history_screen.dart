import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/chat/call/call_history_store.dart';
import 'package:chatkuy/ui/chat/call/call_argument.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> with BaseLayout {
  final CallRepository repository = getIt<CallRepository>();
  final UserRepository userRepository = getIt<UserRepository>();
  late final CallHistoryStore store = CallHistoryStore(userRepository: userRepository);
  final TextEditingController _searchController = TextEditingController();
  Future<String?>? _uidFuture;

  @override
  void initState() {
    super.initState();
    _uidFuture = store.resolveAuthenticatedUid();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Scaffold(
        appBar: store.isSearching ? _buildSearchAppBar() : _buildDefaultAppBar(),
        body: FutureBuilder<String?>(
          future: _uidFuture,
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final currentUid = authSnapshot.data;
            if (currentUid == null) {
              return const Center(child: Text('Silakan masuk kembali'));
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: repository.watchCallHistory(uid: currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }

                store.setCallDocs(
                  docs: snapshot.data?.docs ?? const [],
                  currentUid: currentUid,
                );

                return Observer(
                  builder: (_) {
                    final groups = store.filteredGroups;
                    if (groups.isEmpty) {
                      return Center(child: Text(store.emptyMessage));
                    }

                    return ListView.separated(
                      padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => SizedBox(height: 2.h),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return _CallHistoryTile(
                          group: group,
                          currentUid: currentUid,
                          userRepository: userRepository,
                          onUserResolved: (user) => store.cachePeerName(
                            uid: group.peerUid,
                            name: user.name,
                          ),
                          onTap: () => Get.to(
                            () => CallInfoScreen(
                              group: group,
                              currentUid: currentUid,
                            ),
                          ),
                          onCallTap: () => _startCall(
                            group: group,
                            currentUid: currentUid,
                            isVideoCall: group.latest.isVideoCall,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Telepon',
        style: TextStyle(fontSize: 28.sp),
      ),
      actions: [
        IconButton(
          tooltip: 'Cari',
          onPressed: store.showSearch,
          icon: const Icon(Icons.search),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      leading: IconButton(
        tooltip: 'Tutup pencarian',
        onPressed: _hideSearch,
        icon: const Icon(Icons.arrow_back),
      ),
      titleSpacing: 0,
      title: SizedBox(
        height: 38.h,
        child: TextField(
          controller: _searchController,
          autofocus: true,
          cursorHeight: 18.h,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 14.sp),
          onChanged: store.setSearchQuery,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.72,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide.none,
            ),
            hintText: 'Cari riwayat panggilan',
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
              tooltip: 'Bersihkan pencarian',
              onPressed: () {
                _searchController.clear();
                store.clearSearch();
              },
              icon: const Icon(Icons.close),
            );
          },
        ),
      ],
    );
  }

  void _hideSearch() {
    store.hideSearch();
    _searchController.clear();
  }

  void _startCall({
    required CallHistoryGroup group,
    required String currentUid,
    required bool isVideoCall,
  }) {
    Get.toNamed(
      AppRouteName.CALL_SCREEN,
      arguments: CallArgument(
        roomId: group.latest.roomId,
        currentUid: currentUid,
        targetUid: group.peerUid,
        targetName: group.peerName,
        currentUserName: 'ChatKuy',
        isCaller: true,
        isVideoCall: isVideoCall,
      ),
    );
  }
}

class CallInfoScreen extends StatelessWidget with BaseLayout {
  CallInfoScreen({
    super.key,
    required this.group,
    required this.currentUid,
  });

  final CallHistoryGroup group;
  final String currentUid;
  final UserRepository userRepository = getIt<UserRepository>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info panggilan'),
      ),
      body: FutureBuilder<UserModel?>(
        future: _resolvePeerUser(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          return ListView(
            padding: EdgeInsets.only(bottom: 24.h),
            children: [
              18.verticalSpace,
              Center(
                child: ProfileAvatarWidget(
                  base64Image: user?.photoUrl,
                  size: 112,
                ),
              ),
              14.verticalSpace,
              Text(
                user?.name ?? group.peerName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (user?.username?.isNotEmpty == true) ...[
                4.verticalSpace,
                Text(
                  '@${user!.username}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              24.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _CallInfoAction(
                        icon: Icons.chat_outlined,
                        label: 'Pesan',
                        onTap: () => _openMessage(user),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: _CallInfoAction(
                        icon: Icons.call_outlined,
                        label: 'Audio',
                        onTap: () => _startCall(isVideoCall: false),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: _CallInfoAction(
                        icon: Icons.videocam_outlined,
                        label: 'Video',
                        onTap: () => _startCall(isVideoCall: true),
                      ),
                    ),
                  ],
                ),
              ),
              28.verticalSpace,
              Divider(height: 1.h),
              ..._buildCallRows(context),
            ],
          );
        },
      ),
    );
  }

  Future<UserModel?> _resolvePeerUser() async {
    try {
      return await userRepository.getUser(group.peerUid);
    } catch (_) {
      return null;
    }
  }

  List<Widget> _buildCallRows(BuildContext context) {
    final rows = <Widget>[];
    String? lastHeader;

    for (final entry in group.entries) {
      final header = entry.dayHeaderLabel;
      if (header != lastHeader) {
        rows.add(
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 8.h),
            child: Text(
              header,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
        lastHeader = header;
      }

      rows.add(_CallInfoRow(entry: entry));
    }

    return rows;
  }

  void _openMessage(UserModel? user) {
    Get.toNamed(
      AppRouteName.CHAT_ROOM_SCREEN,
      arguments: ChatRoomArgument(
        roomId: group.latest.roomId,
        currentUid: currentUid,
        targetUser: user ??
            UserModel(
              id: group.peerUid,
              name: group.peerName,
              email: '',
              isEmailVerified: false,
              fcmToken: '',
            ),
      ),
    );
  }

  void _startCall({required bool isVideoCall}) {
    Get.toNamed(
      AppRouteName.CALL_SCREEN,
      arguments: CallArgument(
        roomId: group.latest.roomId,
        currentUid: currentUid,
        targetUid: group.peerUid,
        targetName: group.peerName,
        currentUserName: 'ChatKuy',
        isCaller: true,
        isVideoCall: isVideoCall,
      ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  const _CallHistoryTile({
    required this.group,
    required this.currentUid,
    required this.userRepository,
    required this.onUserResolved,
    required this.onTap,
    required this.onCallTap,
  });

  final CallHistoryGroup group;
  final String currentUid;
  final UserRepository userRepository;
  final ValueChanged<UserModel> onUserResolved;
  final VoidCallback onTap;
  final VoidCallback onCallTap;

  @override
  Widget build(BuildContext context) {
    final latest = group.latest;
    final isMissed = latest.isMissedIncoming;
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<UserModel?>(
      future: _resolvePeerUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onUserResolved(user);
          });
        }

        return ListTile(
          onTap: onTap,
          leading: ProfileAvatarWidget(
            base64Image: user?.photoUrl,
            size: 48,
          ),
          title: Text(
            group.displayTitle(user?.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isMissed ? Colors.redAccent : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                latest.isOutgoing ? Icons.call_made : Icons.call_received,
                size: 16.r,
                color: isMissed ? Colors.redAccent : Colors.green,
              ),
              4.horizontalSpace,
              Flexible(
                child: Text(
                  latest.listDateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            tooltip: latest.isVideoCall ? 'Panggilan video' : 'Panggilan suara',
            onPressed: onCallTap,
            icon: Icon(
              latest.isVideoCall ? Icons.videocam_outlined : Icons.call_outlined,
            ),
          ),
        );
      },
    );
  }

  Future<UserModel?> _resolvePeerUser() async {
    try {
      return await userRepository.getUser(group.peerUid);
    } catch (_) {
      return null;
    }
  }
}

class _CallInfoAction extends StatelessWidget {
  const _CallInfoAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 82.h,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green, size: 24.r),
            8.verticalSpace,
            Text(label, style: TextStyle(fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }
}

class _CallInfoRow extends StatelessWidget {
  const _CallInfoRow({required this.entry});

  final CallHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isMissed = entry.isMissedIncoming;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        entry.isOutgoing ? Icons.call_made : Icons.call_received,
        color: isMissed ? Colors.redAccent : Colors.green,
      ),
      title: Text(entry.directionLabel),
      subtitle: Text(entry.timeLabel),
      trailing: Text(
        entry.resultLabel,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
