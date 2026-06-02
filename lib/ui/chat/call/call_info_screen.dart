import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/chat/call/call_history_store.dart';
import 'package:chatkuy/ui/chat/call/call_argument.dart';
import 'package:chatkuy/ui/chat/call/widget/call_info_action.dart';
import 'package:chatkuy/ui/chat/call/widget/call_info_row.dart';
import 'package:chatkuy/ui/chat/call/widget/call_info_skeleton_view.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
        title: Text(AppTranslationKey.callInfo.tr),
      ),
      body: FutureBuilder<UserModel?>(
        future: _resolvePeerUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CallInfoSkeletonView(rowCount: group.entries.length);
          }

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
                      child: CallInfoAction(
                        icon: Icons.chat_outlined,
                        label: AppTranslationKey.message.tr,
                        onTap: () => _openMessage(user),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: CallInfoAction(
                        icon: Icons.call_outlined,
                        label: AppTranslationKey.audio.tr,
                        onTap: () => _startCall(isVideoCall: false),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: CallInfoAction(
                        icon: Icons.videocam_outlined,
                        label: AppTranslationKey.video.tr,
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

      rows.add(CallInfoRow(entry: entry));
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
