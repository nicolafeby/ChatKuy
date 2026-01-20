import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/appbar_widget.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_password_widget.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/profile/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> with BaseLayout {
  ProfileStore store = ProfileStore(
    presenceRepository: getIt<PresenceRepository>(),
    authRepository: getIt<AuthRepository>(),
    storageRepository: getIt<SecureStorageRepository>(),
  );

  List<ReactionDisposer> _reaction = [];

  @override
  void dispose() {
    for (var d in _reaction) {
      d();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _reaction = [
      reaction((p0) => store.changePasswordFuture?.status, (p0) {
        if (p0 == FutureStatus.pending) {
          showLoading();
        } else {
          dismissLoading();
        }
      }),
      reaction((p0) => store.error.general, (p0) {
        if (p0 == null) return;
        Get.bottomSheet(
          BottomsheetWidget(
            asset: AppAsset.imgFaceSad,
            title: AppStrings.oopsTerjadiKesalahan,
            message: p0.message ?? '',
          ),
        );
      })
    ];
  }

  PreferredSizeWidget _buildAppbar() {
    return AppbarWidget(title: 'Ganti Password');
  }

  Widget _buildBody() {
    return Observer(
      builder: (_) => Column(
        children: [
          Expanded(
            child: Column(
              children: [
                TextfieldPasswordWidget.verify(
                  onValidPassword: (password) {
                    store.currentPassword = password;
                  },
                  label: 'Password Sekarang',
                  hintText: 'Masukan password sekarang',
                ),
                20.verticalSpace,
                TextfieldPasswordWidget.create(
                  onValidPassword: (password) {
                    store.newPassword = password;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 0,
            child: ButtonWidget(
              onPressed: store.canChangePassword
                  ? () => store.changePassword(
                        onSuccess: () async {
                          Get.offAllNamed(AppRouteName.LOGIN_SCREEN);
                          await Future.delayed(Duration(milliseconds: 200));
                          showSnackbar(title: 'Sukses', message: 'Kamu harus login ulang setelah mengganti password');
                        },
                      )
                  : null,
              title: 'Ubah Password',
            ),
          ),
        ],
      ).paddingAll(20.r),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _buildAppbar(),
      body: _buildBody(),
    );
  }
}
