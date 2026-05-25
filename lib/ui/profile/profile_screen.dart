import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/config/theme/theme_controller.dart';
import 'package:chatkuy/core/helpers/image_cropper_helper.dart';
import 'package:chatkuy/core/helpers/imahe_picker_helper.dart';
import 'package:chatkuy/core/helpers/permission_handeler_helper.dart';
import 'package:chatkuy/core/utils/converter/xfile_to_string_converter.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/core/widgets/profile_avatar_widget.dart';
import 'package:chatkuy/core/widgets/skeleton.dart';
import 'package:chatkuy/data/models/edit_profile_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/profile/profile_store.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:chatkuy/ui/profile/widget/profile_bbutton_widget.dart';
import 'package:chatkuy/ui/profile/widget/profile_information_box_widget.dart';
import 'package:chatkuy/ui/profile/widget/profile_preferences_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with BaseLayout {
  ProfileStore store = ProfileStore(
    presenceRepository: getIt<PresenceRepository>(),
    authRepository: getIt<AuthRepository>(),
    storageRepository: getIt<SecureStorageRepository>(),
  );

  List<ReactionDisposer> _reaction = [];
  bool _isResolvingProfile = true;

  @override
  void initState() {
    super.initState();
    init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reaction = [
        reaction((p0) => store.changeProfilePictureFuture?.status, (p0) {
          if (p0 == FutureStatus.pending) {
            showLoading(text: 'Mengunggah gambar...');
          } else {
            dismissLoading();
          }
        })
      ];
    });
  }

  @override
  void dispose() {
    for (var d in _reaction) {
      d();
    }
    super.dispose();
  }

  void init() async {
    try {
      final id = await getIt<SecureStorageRepository>().getUserId();

      if (id != null) {
        await store.getUserProfile(id);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingProfile = false;
        });
      }
    }
  }

  Widget _buildAccoungSettingSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaturan Akun',
          style: TextStyle(fontSize: 18.sp),
        ),
        8.verticalSpace,
        ProfileButtonWidget(
          title: Text('Ubah Email', style: TextStyle(fontSize: 12.sp)),
          leading: Icon(Icons.email_outlined, size: 20.r),
          onTap: () {
            final email = store.user?.email;

            if (email == null) return;
            Get.toNamed(
              AppRouteName.EDIT_EMAIL_SCREEN,
              arguments: ChangeEmailArgument(currentEmail: email),
            );
          },
        ),
        ProfileButtonWidget(
          title: Text('Ubah Password', style: TextStyle(fontSize: 12.sp)),
          leading: Icon(Icons.password_outlined, size: 20.r),
          onTap: () => Get.toNamed(AppRouteName.CHANGE_PASSWORD_SCREEN),
        ),
      ],
    );
  }

  void _showDialog() {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 60.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Opsi',
              style: TextStyle(fontSize: 18.sp),
            ),
            10.verticalSpace,
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 6.r),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () async {
                handlePermission(
                  permission: Permission.mediaLibrary,
                  onSuccess: () async {
                    dismissLoading();
                    final image = await ImagePickerHelper.pickImage(
                      source: PickImageSource.gallery,
                    );

                    if (image == null) return;
                    final croppedImage =
                        await ImageCropperHelper.cropImage(imageFile: image);

                    if (croppedImage == null) return;
                    final base64 =
                        await FileConverterHelper.fileToBase64(croppedImage);

                    store.changeProfilePicture(imageUrl: base64).then(
                      (value) async {
                        final id =
                            await getIt<SecureStorageRepository>().getUserId();

                        if (id == null) return;
                        return store.getUserProfile(id);
                      },
                    );
                  },
                  onDenied: (p0) {
                    Get.bottomSheet(BottomsheetWidget(
                      asset: AppAsset.imgFaceSad,
                      title: AppStrings.oopsTerjadiKesalahan,
                      message:
                          'Kami tidak mendapatkan akses galeri untuk action ini',
                    ));
                  },
                );
              },
              label: Text(
                'Pilih dari galeri',
                style: TextStyle(fontSize: 16.sp),
              ),
              icon: Icon(Icons.photo_album_outlined),
            ),
            2.verticalSpace,
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 6.r),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                handlePermission(
                  permission: Permission.camera,
                  onSuccess: () async {
                    dismissLoading();
                    final image = await ImagePickerHelper.pickImage(
                      source: PickImageSource.camera,
                    );

                    if (image == null) return;
                    final croppedImage =
                        await ImageCropperHelper.cropImage(imageFile: image);

                    if (croppedImage == null) return;
                    final base64 =
                        await FileConverterHelper.fileToBase64(croppedImage);

                    store.changeProfilePicture(imageUrl: base64).then(
                      (value) async {
                        final id =
                            await getIt<SecureStorageRepository>().getUserId();

                        if (id == null) return;
                        return store.getUserProfile(id);
                      },
                    );
                  },
                  onDenied: (p0) {
                    Get.bottomSheet(BottomsheetWidget(
                      asset: AppAsset.imgFaceSad,
                      title: AppStrings.oopsTerjadiKesalahan,
                      message:
                          'Kami tidak mendapatkan akses kamera untuk action ini',
                    ));
                  },
                );
              },
              label: Text(
                'Ambil dari kamera',
                style: TextStyle(fontSize: 16.sp),
              ),
              icon: Icon(Icons.camera_alt_outlined),
            ),
            Visibility(
              visible: store.user?.photoUrl == null ? false : true,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.r, vertical: 6.r),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  store.changeProfilePicture(imageUrl: null).then(
                    (value) async {
                      final id =
                          await getIt<SecureStorageRepository>().getUserId();

                      if (id == null) return;
                      return store.getUserProfile(id);
                    },
                  );
                },
                label: Text(
                  'Hapus foto profil',
                  style: TextStyle(fontSize: 16.sp),
                ),
                icon: Icon(Icons.delete_outline),
              ).paddingOnly(top: 2.h),
            )
          ],
        ).paddingOnly(top: 12.h, bottom: 8.h),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeOf(context);
    final colorScheme = colorSchemeOf(context);
    final isDarkMode = isDarkModeOf(context);

    return Scaffold(
      body: Observer(
        builder: (context) {
          if (_isResolvingProfile ||
              store.userFuture?.status == FutureStatus.pending) {
            return const ProfileSkeletonView();
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: theme.appBarTheme.backgroundColor,
                foregroundColor: colorScheme.onSurface,
                expandedHeight: 200.h,
                pinned: true,
                elevation: 0,
                centerTitle: true,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final percent = ((constraints.maxHeight - kToolbarHeight) /
                            (260 - kToolbarHeight))
                        .clamp(0.0, 1.0);
                    final gender = store.user?.gender;
                    int? age;

                    if (store.user?.birthDate != null) {
                      age = store.getAge(store.user!.birthDate!);
                    }

                    return FlexibleSpaceBar(
                      title: Opacity(
                        opacity: 1 - percent,
                        child: Text(
                          store.user?.name ?? '-',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      centerTitle: true,
                      background: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(50.r),
                            bottomRight: Radius.circular(50.r),
                          ),
                        ),
                        padding: const EdgeInsets.only(top: 50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            24.verticalSpace,
                            Stack(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.surface),
                                  child: ProfileAvatarWidget(
                                    base64Image: store.user?.photoUrl,
                                    size: 80,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showDialog,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colorScheme.surface,
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 16.r,
                                        color: AppColor.primaryColor,
                                      ).paddingAll(4.r),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            8.verticalSpace,
                            Text(
                              store.user?.name ?? '-',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            4.verticalSpace,
                            if (age == null) ...[
                              Text(
                                gender?.value ?? Gender.secret.value,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ] else ...[
                              Text(
                                "${gender?.value ?? Gender.secret.value}, $age tahun",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ProfilePreferencesWidget(
                          icon: Icon(
                            Icons.online_prediction_outlined,
                            color: Colors.white,
                          ),
                          onTap: () async {
                            final nextValue =
                                !(store.user?.isOnlineStatusVisible ?? true);
                            await store.updateOnlineStatusVisibility(nextValue);
                            showSnackbar(
                              title: 'Privasi Online',
                              message: nextValue
                                  ? 'Status online kamu bisa dilihat teman.'
                                  : 'Status online kamu disembunyikan. Kamu juga tidak bisa melihat status online teman.',
                            );
                          },
                          title: store.user?.isOnlineStatusVisible == false
                              ? 'Offline'
                              : 'Online',
                        ),
                        ProfilePreferencesWidget(
                          icon: Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                          ),
                          onTap: () {
                            showComingSoonSnackbar();
                          },
                          title: 'Notifikasi',
                        ),
                        ProfilePreferencesWidget(
                          icon: Icon(
                            isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: Colors.white,
                          ),
                          onTap: getIt<ThemeController>().toggleTheme,
                          title: isDarkMode ? 'Gelap' : 'Terang',
                        ),
                      ],
                    ),
                    24.verticalSpace,
                    Row(
                      children: [
                        Text(
                          'Informasi Personal',
                          style: TextStyle(fontSize: 18.sp),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final userData = store.user;

                            if (userData == null) return;
                            Get.toNamed(
                              AppRouteName.EDIT_PROFILE_SCREEN,
                              arguments: EditProfileArgument(
                                userData: EditProfileModel(
                                  email: userData.email,
                                  gender: userData.gender ?? Gender.secret,
                                  name: userData.name,
                                  username: userData.username ?? '',
                                  birthDate: userData.birthDate,
                                ),
                              ),
                            )?.then(
                              (value) async {
                                if (value != true) return;

                                final id =
                                    await getIt<SecureStorageRepository>()
                                        .getUserId();

                                if (id == null) return;
                                store.getUserProfile(id);
                                showSnackbar(
                                    title: 'Sukses',
                                    message: 'Berhasil Mengubah Profile');
                              },
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                'Ubah',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColor.primaryColor,
                                ),
                              ),
                              4.horizontalSpace,
                              Icon(
                                Icons.edit_outlined,
                                size: 16.r,
                                color: AppColor.primaryColor,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    16.verticalSpace,
                    ProfileInformationBoxWidget(
                      title: 'Jenis kelamin',
                      icon: Icon(
                        Icons.male,
                        color: Colors.grey,
                      ),
                      value: store.user?.gender?.value ?? Gender.secret.value,
                    ),
                    16.verticalSpace,
                    ProfileInformationBoxWidget(
                      title: 'Username',
                      icon: Icon(
                        Icons.person_2_outlined,
                        color: Colors.grey,
                      ),
                      value: store.user?.username ?? '',
                    ),
                    16.verticalSpace,
                    ProfileInformationBoxWidget(
                      title: 'Tanggal lahir',
                      icon: Icon(
                        Icons.cake_outlined,
                        color: Colors.grey,
                      ),
                      value: _formatBirthDate(store.user?.birthDate),
                    ),
                    16.verticalSpace,
                    ProfileInformationBoxWidget(
                      title: 'Nomor HP',
                      icon: Icon(
                        Icons.phone_android_sharp,
                        color: Colors.grey,
                      ),
                      value: '0912929222',
                    ),
                    16.verticalSpace,
                    ProfileInformationBoxWidget(
                      title: 'Email',
                      icon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey,
                      ),
                      value: store.user?.email ?? '',
                    ),
                    16.verticalSpace,
                    _buildPrivacySections(),
                    16.verticalSpace,
                    _buildAccoungSettingSections(),
                    80.verticalSpace,
                    TextButton(
                      onPressed: () {
                        store.logout(
                          onSuccess: () =>
                              Get.offAllNamed(AppRouteName.LOGIN_SCREEN),
                        );
                      },
                      child: Text(
                        'Keluar',
                        style: TextStyle(fontSize: 18.sp, color: Colors.red),
                      ),
                    ),
                    32.verticalSpace,
                    Text(
                      store.appVersion ?? '',
                      style: TextStyle(color: Colors.grey),
                    ),
                    16.verticalSpace,
                  ],
                ).paddingAll(20.r),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatBirthDate(DateTime? date) {
    if (date == null) return '-';

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildPrivacySections() {
    final colorScheme = colorSchemeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privasi Profil',
          style: TextStyle(fontSize: 18.sp),
        ),
        8.verticalSpace,
        _PrivacySwitchTile(
          icon: Icons.email_outlined,
          title: 'Tampilkan email',
          subtitle: 'Izinkan teman melihat alamat email kamu',
          value: store.user?.isEmailVisible ?? true,
          colorScheme: colorScheme,
          onChanged: store.updateEmailVisibility,
        ),
        8.verticalSpace,
        _PrivacySwitchTile(
          icon: Icons.cake_outlined,
          title: 'Tampilkan tanggal lahir',
          subtitle: 'Izinkan teman melihat tanggal lahir kamu',
          value: store.user?.isBirthDateVisible ?? true,
          colorScheme: colorScheme,
          onChanged: store.updateBirthDateVisibility,
        ),
        8.verticalSpace,
        _PrivacySwitchTile(
          icon: Icons.online_prediction_outlined,
          title: 'Tampilkan status online',
          subtitle:
              'Jika dimatikan, kamu juga tidak bisa melihat status online teman',
          value: store.user?.isOnlineStatusVisible ?? true,
          colorScheme: colorScheme,
          onChanged: store.updateOnlineStatusVisibility,
        ),
      ],
    );
  }
}

class _PrivacySwitchTile extends StatelessWidget {
  const _PrivacySwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.colorScheme,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ColorScheme colorScheme;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: Colors.grey),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
