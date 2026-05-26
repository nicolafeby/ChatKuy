import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/skeleton.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/chat/call/call_history_store.dart';
import 'package:chatkuy/ui/chat/call/call_argument.dart';
import 'package:chatkuy/ui/chat/call/call_info_screen.dart';
import 'package:chatkuy/ui/chat/call/widget/call_history_tile.dart';
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
              return const ListTileSkeletonList();
            }

            final currentUid = authSnapshot.data;
            if (currentUid == null) {
              return const Center(child: Text('Silakan masuk kembali'));
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: repository.watchCallHistory(uid: currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTileSkeletonList();
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
                        return CallHistoryTile(
                          group: group,
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
