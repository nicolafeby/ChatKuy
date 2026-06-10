import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/skeleton.dart';
import 'package:chatkuy/data/repositories/friend_request_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/friend/friend_request/friend_request_store.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestScreen>
    with SingleTickerProviderStateMixin, BaseLayout {
  FriendRequestStore store = FriendRequestStore(
    repository: getIt<FriendRequestRepository>(),
  );
  late final TabController _tabController;

  List<ReactionDisposer> _reaction = [];

  @override
  void initState() {
    super.initState();
    store.init();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reaction = [
        reaction((p0) => store.isLoading, (p0) {
          if (p0 == true) {
            showLoading();
          } else {
            dismissLoading();
          }
        }),
      ];
    });
  }

  @override
  void dispose() {
    store.dispose();
    _tabController.dispose();
    for (var d in _reaction) {
      d();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppTranslationKey.friendRequests.tr,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor:
            isDarkModeOf(context) ? const Color(0xFF111B21) : Colors.white,
        surfaceTintColor:
            isDarkModeOf(context) ? const Color(0xFF111B21) : Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColor.primaryColor,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: AppColor.primaryColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: AppTranslationKey.incomingRequests.tr),
            Tab(text: AppTranslationKey.sentRequests.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IncomingRequestTab(store: store),
          _OutgoingRequestTab(store: store),
        ],
      ),
    );
  }
}

class _IncomingRequestTab extends StatelessWidget {
  const _IncomingRequestTab({
    required this.store,
  });

  final FriendRequestStore store;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final data = store.incomingRequests?.value;

        if (data == null) {
          return const ListTileSkeletonList();
        }

        if (data.isEmpty) {
          return _RequestEmptyState(
              label: AppTranslationKey.noIncomingRequests.tr);
        }

        return ListView.separated(
          padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
          itemCount: data.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 84.w,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.22
                      : 0.5,
                ),
          ),
          itemBuilder: (_, index) {
            final request = data[index];

            return ListTile(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              leading: _RequestAvatar(photoUrl: request.photoUrl),
              title: Text(
                request.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '@${request.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Observer(
                builder: (_) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: AppTranslationKey.reject.tr,
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () async {
                          await store.rejectFriendRequest(
                            senderUid: request.fromUid,
                          );
                        },
                      ),
                      IconButton(
                        tooltip: AppTranslationKey.accept.tr,
                        icon: const Icon(
                          Icons.check,
                          color: AppColor.primaryColor,
                        ),
                        onPressed: () async {
                          await store.accept(
                            requestId: request.id,
                            fromUid: request.fromUid,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _OutgoingRequestTab extends StatelessWidget {
  const _OutgoingRequestTab({
    required this.store,
  });

  final FriendRequestStore store;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final data = store.outgoingRequests?.value;

        if (data == null) {
          return const ListTileSkeletonList(showSubtitleIcon: false);
        }

        if (data.isEmpty) {
          return _RequestEmptyState(label: AppTranslationKey.noSentRequests.tr);
        }

        return ListView.separated(
          padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
          itemCount: data.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 84.w,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.22
                      : 0.5,
                ),
          ),
          itemBuilder: (_, index) {
            final request = data[index];

            return ListTile(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              leading: _RequestAvatar(photoUrl: request.photoUrl),
              title: Text(
                request.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      '@${request.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  8.horizontalSpace,
                  Icon(Icons.access_time, size: 14.r, color: Colors.orange),
                  4.horizontalSpace,
                  Flexible(
                    child: Text(
                      AppTranslationKey.waitingApproval.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: TextButton(
                onPressed: () async => await store.cancelFriendRequest(
                  targetUid: request.toUid,
                ),
                child: Text(
                  AppTranslationKey.cancel.tr,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RequestAvatar extends StatelessWidget {
  const _RequestAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26.r,
      backgroundColor: AppColor.primaryColor.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.32 : 0.14,
      ),
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Icon(
              Icons.person,
              color: AppColor.primaryColor,
              size: 26.r,
            )
          : null,
    );
  }
}

class _RequestEmptyState extends StatelessWidget {
  const _RequestEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15.sp,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
