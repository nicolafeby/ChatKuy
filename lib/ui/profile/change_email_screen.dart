import 'package:chatkuy/core/widgets/appbar_widget.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_password_widget.dart';
import 'package:chatkuy/core/widgets/textfield/textfield_widget.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/profile/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChangeEmailArgument {
  const ChangeEmailArgument({required this.currentEmail});

  final String currentEmail;
}

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> with BaseLayout {
  ProfileStore store = ProfileStore(
    presenceRepository: getIt<PresenceRepository>(),
    authRepository: getIt<AuthRepository>(),
    storageRepository: getIt<SecureStorageRepository>(),
  );

  ChangeEmailArgument? argument;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ChangeEmailArgument?;
    store.currentEmail = argument?.currentEmail;
  }

  PreferredSizeWidget _buildAppbar() {
    return AppbarWidget(title: 'Ubah Alamat Email');
  }

  Widget _buildBody() {
    return Observer(
      builder: (_) => Column(
        children: [
          Expanded(
            child: Column(
              children: [
                TextfieldWidget(
                  label: 'Email Baru',
                  hintText: 'Masukan email baru kamu',
                  textInputAction: TextInputAction.next,
                  textInputType: TextInputType.emailAddress,
                  errorText: store.error.email,
                  onChanged: store.validateEmail,
                ),
                12.verticalSpace,
                TextfieldPasswordWidget.verify(
                  onValidPassword: (password) {
                    store.password = password;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 0,
            child: ButtonWidget(
              onPressed: store.canChangeEmail ? () => showComingSoonSnackbar() : null,
              title: 'Konfirmasi',
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
