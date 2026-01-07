import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/ui/chat/chat_list/widget/chat_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/utils.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Chat',
        style: TextStyle(fontSize: 28.sp),
      ),
      actions: [
        Image.asset(
          AppAsset.icEditOutlined,
          height: 24.r,
        ).paddingOnly(right: 20.r)
      ],
    );
  }

  Widget _buildBody() {
    return ListView.separated(
      padding: EdgeInsets.all(20.r),
      itemBuilder: (context, index) => ChatItemWidget(),
      separatorBuilder: (context, index) => 16.verticalSpace,
      itemCount: 12,
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
