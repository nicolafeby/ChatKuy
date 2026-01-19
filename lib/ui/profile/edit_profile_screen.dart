import 'package:chatkuy/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

class EditProfileArgument {
  const EditProfileArgument({required this.userData});

  final UserModel userData;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  EditProfileArgument? argument;
  List<ReactionDisposer> _reaction = [];

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as EditProfileArgument?;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reaction = [];
    });
  }

  @override
  void dispose() {
    for (var d in _reaction) {
      d();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          'Ubah Profil',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
    );
  }
}
