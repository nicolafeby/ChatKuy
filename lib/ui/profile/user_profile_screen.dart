import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/utils/extension/string.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_media_gallery_screen.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_room_screen.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class UserProfileArgument {
  const UserProfileArgument({
    required this.targetUser,
    this.roomId,
    this.currentUid,
  });

  final UserModel targetUser;
  final String? roomId;
  final String? currentUid;
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with BaseLayout {
  final UserRepository _userRepository = getIt<UserRepository>();
  final ChatRepository _chatRepository = getIt<ChatRepository>();
  final SecureStorageRepository _storageRepository =
      getIt<SecureStorageRepository>();

  UserProfileArgument? argument;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as UserProfileArgument?;
  }

  @override
  Widget build(BuildContext context) {
    if (argument == null) return const SizedBox.shrink();

    return StreamBuilder<UserModel>(
      initialData: argument!.targetUser,
      stream: _userRepository.watchUser(argument!.targetUser.id),
      builder: (context, targetSnapshot) {
        final targetUser = targetSnapshot.data ?? argument!.targetUser;

        return FutureBuilder<String?>(
          future: _storageRepository.getUserId(),
          builder: (context, uidSnapshot) {
            final currentUid = argument!.currentUid ?? uidSnapshot.data;

            if (currentUid == null) {
              return _buildScaffold(
                targetUser: targetUser,
                canViewPresence: false,
                currentUid: null,
              );
            }

            return StreamBuilder<UserModel>(
              stream: _userRepository.watchUser(currentUid),
              builder: (context, currentSnapshot) {
                final currentUser = currentSnapshot.data;
                final canViewPresence =
                    currentUser?.isOnlineStatusVisible == true &&
                        targetUser.isOnlineStatusVisible;

                return _buildScaffold(
                  targetUser: targetUser,
                  canViewPresence: canViewPresence,
                  currentUid: currentUid,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildScaffold({
    required UserModel targetUser,
    required bool canViewPresence,
    required String? currentUid,
  }) {
    final colorScheme = colorSchemeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslationKey.profile.tr),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        children: [
          Center(
            child: GestureDetector(
              onTap: targetUser.photoUrl == null
                  ? null
                  : () => _showProfilePhoto(targetUser),
              child: ProfileAvatarWidget(
                base64Image: targetUser.photoUrl,
                size: 112,
              ),
            ),
          ),
          14.verticalSpace,
          Text(
            targetUser.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (targetUser.username?.isNotEmpty == true) ...[
            4.verticalSpace,
            Text(
              '@${targetUser.username}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          8.verticalSpace,
          Text(
            _presenceText(targetUser, canViewPresence),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          24.verticalSpace,
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: currentUid == null
                      ? null
                      : () => _openChat(targetUser, currentUid),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(AppTranslationKey.chat.tr),
                ),
              ),
            ],
          ),
          24.verticalSpace,
          if (argument?.roomId != null) ...[
            _ActionTile(
              icon: Icons.collections_outlined,
              title: AppTranslationKey.mediaGallery.tr,
              subtitle:
                  '${AppTranslationKey.media.tr} • ${AppTranslationKey.files.tr} • ${AppTranslationKey.links.tr}',
              onTap: () => _openMediaGallery(targetUser),
            ),
            12.verticalSpace,
          ],
          _InfoTile(
            icon: Icons.person_2_outlined,
            title: AppTranslationKey.username.tr,
            value: targetUser.username?.isNotEmpty == true
                ? '@${targetUser.username}'
                : '-',
          ),
          _InfoTile(
            icon: Icons.email_outlined,
            title: AppTranslationKey.email.tr,
            value: targetUser.isEmailVisible
                ? targetUser.email
                : AppTranslationKey.birthDateHidden.tr,
          ),
          _InfoTile(
            icon: Icons.cake_outlined,
            title: AppTranslationKey.birthDate.tr,
            value: targetUser.isBirthDateVisible
                ? _formatBirthDate(targetUser.birthDate)
                : AppTranslationKey.birthDateHidden.tr,
          ),
          _InfoTile(
            icon: Icons.wc_outlined,
            title: AppTranslationKey.gender.tr,
            value: targetUser.gender?.value ?? Gender.secret.value,
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(UserModel targetUser, String currentUid) async {
    if (argument?.roomId != null) {
      Get.back();
      return;
    }

    final roomId = argument?.roomId ??
        await _chatRepository.createOrGetRoom(
          currentUid: currentUid,
          targetUid: targetUser.id,
        );

    Get.toNamed(
      AppRouteName.CHAT_ROOM_SCREEN,
      arguments: ChatRoomArgument(
        roomId: roomId,
        currentUid: currentUid,
        targetUser: targetUser,
      ),
    );
  }

  void _openMediaGallery(UserModel targetUser) {
    final roomId = argument?.roomId;
    if (roomId == null) return;

    Get.toNamed(
      AppRouteName.CHAT_MEDIA_GALLERY_SCREEN,
      arguments: ChatMediaGalleryArgument(
        roomName: targetUser.name,
        roomId: roomId,
        messages: const [],
      ),
    );
  }

  void _showProfilePhoto(UserModel user) {
    final image = user.photoUrl;
    if (image == null) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: InteractiveViewer(
              child: Image.memory(
                image.base64GzipToBytes(),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _presenceText(UserModel user, bool canViewPresence) {
    if (!canViewPresence) return AppTranslationKey.hiddenOnlineStatus.tr;
    if (user.isOnline == true) return AppTranslationKey.online.tr;
    final lastOnlineAt = user.lastOnlineAt;
    if (lastOnlineAt == null) return AppTranslationKey.offline.tr;
    return AppTranslationKey.lastOnlineAt
        .trParams({'time': lastOnlineAt.daysAndTime});
  }

  String _formatBirthDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: AppColor.primaryColor.withValues(alpha: 0.12),
        child: Icon(icon, color: AppColor.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColor.primaryColor.withValues(alpha: 0.12),
        child: Icon(icon, color: AppColor.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
