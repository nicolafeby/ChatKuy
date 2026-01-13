import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/auth/login/login_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with BaseLayout {
  LoginStore store = LoginStore(
    service: getIt<AuthRepository>(),
    storageService: getIt<SecureStorageRepository>(),
    presenceService: getIt<PresenceRepository>(),
  );

  @override
  void initState() {
    super.initState();
  }

  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Profil',
        style: TextStyle(fontSize: 28.sp),
      ),
      actions: [
        GestureDetector(
          onTap: () => store.logout(
            onSuccess: () => Get.offAllNamed(AppRouteName.LOGIN_SCREEN),
          ),
          child: Icon(Icons.logout).paddingOnly(right: 16.r),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: _buildBody(),
    );
  }
}
