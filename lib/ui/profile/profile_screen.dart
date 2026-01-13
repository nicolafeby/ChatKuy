import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/profile/profile_store.dart';
import 'package:chatkuy/ui/profile/widget/profile_information_box_widget.dart';
import 'package:chatkuy/ui/profile/widget/profile_preferences_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

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

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final id = await getIt<SecureStorageRepository>().getUserId();

    if (id == null) return;
    store.getUserProfile(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Observer(
        builder: (context) {
          if (store.userFuture?.status == FutureStatus.pending) {
            return Center(child: CircularProgressIndicator());
          }
          
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.white,
                expandedHeight: 200.h,
                pinned: true,
                elevation: 0,
                centerTitle: true,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final percent = ((constraints.maxHeight - kToolbarHeight) / (260 - kToolbarHeight)).clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      title: Opacity(
                        opacity: 1 - percent,
                        child: Text(
                          store.user?.name ?? '-',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      centerTitle: true,
                      background: Container(
                        decoration: BoxDecoration(
                          color: AppColor.whiteBlue,
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
                            Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                              child: SizedBox(
                                height: 80.r,
                                width: 80.r,
                                child: CircleAvatar(
                                  backgroundImage:
                                      store.user?.photoUrl != null ? NetworkImage(store.user!.photoUrl!) : null,
                                  child: store.user?.photoUrl == null
                                      ? Text(
                                          store.user?.name[0].toUpperCase() ?? '',
                                          style: TextStyle(fontSize: 32.sp),
                                        )
                                      : null,
                                ),
                              ),
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
                            const Text(
                              "Male 25 .y",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
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
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Informasi Personal',
                          style: TextStyle(fontSize: 18.sp),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () {
                            // TODO: edit personal information
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ProfilePreferencesWidget(
                          icon: Icon(
                            Icons.online_prediction_outlined,
                            color: Colors.white,
                          ),
                          onTap: () {},
                          title: 'Online',
                        ),
                        ProfilePreferencesWidget(
                          icon: Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                          ),
                          onTap: () {},
                          title: 'Notifikasi',
                        ),
                        ProfilePreferencesWidget(
                          icon: Icon(
                            Icons.sunny,
                            color: Colors.white,
                          ),
                          onTap: () {},
                          title: 'Terang',
                        ),
                      ],
                    ),
                    24.verticalSpace,
                    ProfileInformationBoxWidget(
                      title: 'Jenis kelamin',
                      icon: Icon(
                        Icons.male,
                        color: Colors.grey,
                      ),
                      value: 'Laki-laki',
                      onTap: () {},
                    ),
                    16.verticalSpace,
                    ProfileInformationBoxWidget(
                      title: 'Username',
                      icon: Icon(
                        Icons.person_2_outlined,
                        color: Colors.grey,
                      ),
                      value: 'nclfby',
                      onTap: () {},
                    ),
                    16.verticalSpace,
                    ProfileInformationBoxWidget(
                      title: 'Nomor HP',
                      icon: Icon(
                        Icons.phone_android_sharp,
                        color: Colors.grey,
                      ),
                      value: '0912929222',
                      onTap: () {},
                    ),
                    16.verticalSpace,
                    ProfileInformationBoxWidget(
                      title: 'Email',
                      icon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey,
                      ),
                      value: 'ncl@mail.com',
                      onTap: () {},
                    ),
                    80.verticalSpace,
                    TextButton(
                      onPressed: () {
                        store.logout(
                          onSuccess: () => Get.offAllNamed(AppRouteName.LOGIN_SCREEN),
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
}
