import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Teman',
        style: TextStyle(fontSize: 28.sp),
      ),
      actions: [
        Icon(Icons.person_add).paddingOnly(right: 16.r),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
    );
  }
}
