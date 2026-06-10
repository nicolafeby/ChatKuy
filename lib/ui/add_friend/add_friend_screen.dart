import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/data/repositories/friend_request_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/friend/add_friend_store.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> with BaseLayout {
  AddFriendStore store = AddFriendStore(
    repository: getIt<FriendRequestRepository>(),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:
              isDarkModeOf(context) ? const Color(0xFF111B21) : Colors.white,
          surfaceTintColor:
              isDarkModeOf(context) ? const Color(0xFF111B21) : Colors.white,
          titleSpacing: 0,
          title: Text(
            AppTranslationKey.addFriend.tr,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslationKey.findFriendByUsername.tr,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              14.verticalSpace,
              _UsernameInput(store: store),
              10.verticalSpace,
              Observer(
                builder: (_) {
                  if (store.errorMessage == null) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    store.errorMessage!,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13.sp,
                    ),
                  );
                },
              ),
              const Spacer(),
              Observer(
                builder: (_) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.fromHeight(52.h),
                        elevation: 0,
                        backgroundColor: AppColor.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        disabledForegroundColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        textStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: store.canSubmit
                          ? () async {
                              final success = await store.addFriend();
                              if (!context.mounted) return;

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(AppTranslationKey.friendAdded.tr),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            }
                          : null,
                      child: store.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(AppTranslationKey.addFriend.tr),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsernameInput extends StatelessWidget {
  const _UsernameInput({
    required this.store,
  });

  final AddFriendStore store;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Observer(
      builder: (_) {
        return TextField(
          onChanged: store.setUsername,
          textInputAction: TextInputAction.search,
          cursorColor: AppColor.primaryColor,
          style: TextStyle(
            fontSize: 16.sp,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor:
                isDark ? const Color(0xFF202C33) : const Color(0xFFF0F2F5),
            hintText: AppTranslationKey.usernameExample.tr,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16.sp,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorScheme.onSurfaceVariant,
              size: 24.r,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28.r),
              borderSide: BorderSide(
                color: AppColor.primaryColor,
                width: 1.4.r,
              ),
            ),
          ),
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
        );
      },
    );
  }
}
