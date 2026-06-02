import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/stores/chat/call/call_history_store.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CallHistoryTile extends StatelessWidget {
  const CallHistoryTile({
    super.key,
    required this.group,
    required this.userRepository,
    required this.onUserResolved,
    required this.onTap,
    required this.onCallTap,
  });

  final CallHistoryGroup group;
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
            tooltip: latest.isVideoCall
                ? AppTranslationKey.videoCall.tr
                : AppTranslationKey.voiceCall.tr,
            onPressed: onCallTap,
            icon: Icon(
              latest.isVideoCall
                  ? Icons.videocam_outlined
                  : Icons.call_outlined,
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
