import 'package:chatkuy/core/widgets/appbar_widget.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_widget.dart';
import 'package:chatkuy/data/models/edit_profile_model.dart';
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

class EditProfileArgument {
  const EditProfileArgument({required this.userData});

  final EditProfileModel userData;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with BaseLayout {
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
    store.initEditProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reaction = [
        reaction((p0) => store.editProfileFuture?.status, (p0) async {
          if (p0 == FutureStatus.pending) {
            showLoading();
          } else if (p0 == FutureStatus.fulfilled) {
            dismissLoading();
            await Future.delayed(Duration(milliseconds: 150));
            Get.back<bool>(result: true);
          } else {
            dismissLoading();
          }
        }),
      ];
    });
  }

  Widget _buildBody() {
    return Observer(
      builder: (_) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  _buildNameSections(),
                  12.verticalSpace,
                  // _buildUsernameSections(),
                  12.verticalSpace,
                  // _buildEmailSections(),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 0,
            child: ButtonWidget(
              onPressed: store.hasProfileChanged ? () => store.editProfile() : null,
              title: 'Simpan Perubahan',
            ).paddingAll(20.r),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nama',
          style: TextStyle(fontSize: 16.sp),
        ),
        4.verticalSpace,
        TextfieldWidget(
          label: store.argument?.userData.name ?? '',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintText: store.argument?.userData.name,
          errorText: store.error.name,
          onChanged: store.validateEditName,
        )
      ],
    );
  }

  Widget _buildUsernameSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: TextStyle(fontSize: 16.sp),
        ),
        4.verticalSpace,
        TextfieldWidget(
          label: store.argument?.userData.username ?? '',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintText: store.argument?.userData.username,
          errorText: store.error.username,
          onChanged: store.validateEditUsername,
        ),
      ],
    );
  }

  Widget _buildEmailSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alamat Email',
          style: TextStyle(fontSize: 16.sp),
        ),
        4.verticalSpace,
        TextfieldWidget(
          label: store.argument?.userData.email ?? '',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintText: store.argument?.userData.email,
          errorText: store.error.email,
          onChanged: store.validateEditEmail,
        ),
      ],
    );
  }

  Widget _buildGenderSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: TextStyle(fontSize: 16.sp),
        ),
        4.verticalSpace,
        TextfieldWidget(
          label: store.argument?.userData.email ?? '',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintText: store.argument?.userData.email,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppbarWidget(title: 'Ubah Profile'),
      body: _buildBody(),
    );
  }
}
