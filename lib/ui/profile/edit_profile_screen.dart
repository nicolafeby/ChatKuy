import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/formatter.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/appbar_widget.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_widget.dart';
import 'package:chatkuy/data/models/edit_profile_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/auth/register/register_store.dart';
import 'package:chatkuy/stores/profile/profile_store.dart';
import 'package:chatkuy/ui/_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  _buildUsernameSections(),
                  12.verticalSpace,
                  _buildGenderSections(),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 0,
            child: ButtonWidget(
              onPressed: store.canSaveProfileChanged ? () => store.editProfile() : null,
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
          onChanged: (value) {
            store.validateEditUsername(value);
          },
          inputFormatters: [FilteringTextInputFormatter.allow(AppFormatter.usernameRegex)],
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
          textInputType: TextInputType.emailAddress,
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
        DropdownButtonFormField<Gender>(
          decoration: InputDecoration(
            hintText: store.argument?.userData.gender.value ?? 'Jenis kelamin',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          items: [
            DropdownMenuItem(
                value: Gender.male,
                child: Text(
                  Gender.male.value,
                  // style: TextStyle(fontSize: 12.sp),
                )),
            DropdownMenuItem(
                value: Gender.female,
                child: Text(
                  Gender.female.value,
                  // style: TextStyle(fontSize: 12.sp),
                )),
            DropdownMenuItem(
                value: Gender.secret,
                child: Text(
                  Gender.secret.value,
                  // style: TextStyle(fontSize: 12.sp),
                )),
          ],
          onChanged: (value) {
            if (value == null) return;
            store.onChangeGender(gender: value);
          },
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
