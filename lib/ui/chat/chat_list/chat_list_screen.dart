import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/ui/chat/chat_list/widget/chat_item_widget.dart';
import 'package:chatkuy/ui/chat/chat_list/widget/chat_list_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Percakapan',
        style: TextStyle(fontSize: 28.sp),
      ),
      actions: [
        Image.asset(
          AppAsset.icEditOutlined,
          height: 24.r,
        ).paddingOnly(right: 16.r)
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        ChatListSearchWidget().paddingSymmetric(horizontal: 20.r).paddingOnly(bottom: 8.h),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(20.r),
            itemBuilder: (context, index) => ChatItemWidget(
              onTap: () {
                Get.toNamed(AppRouteName.CHAT_ROOM_SCREEN);
              },
            ),
            separatorBuilder: (context, index) => 16.verticalSpace,
            itemCount: 12,
          ),
        ),
      ],
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
