import 'dart:developer';

import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/chat/chat_list/chat_list_store.dart';
import 'package:chatkuy/ui/chat/chat_list/widget/chat_item_widget.dart';
import 'package:chatkuy/ui/chat/chat_list/widget/chat_list_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  ChatListStore store = ChatListStore(
    chatRepository: getIt<ChatRepository>(),
    authRepository: getIt<AuthRepository>(),
  );

  @override
  void initState() {
    super.initState();
    final currentUid = store.uid;

    /// ambil uid dari auth / session kamu
    /// contoh (sesuaikan dengan project kamu):

    if (currentUid == null) return;
    store.init(currentUid);
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

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

        /// REALTIME CHAT LIST
        Expanded(
          child: Observer(
            builder: (_) {
              final stream = store.chatRooms;

              if (stream == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (stream.error != null) {
                return Center(
                  child: Text(stream.error.toString()),
                );
              }

              final rooms = stream.value ?? [];

              if (rooms.isEmpty) {
                return const Center(
                  child: Text('Belum ada percakapan'),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.all(20.r),
                itemBuilder: (context, index) {
                  final room = rooms[index];

                  return ChatItemWidget(
                    room: room, // asumsi ChatItemWidget terima model
                    onTap: () {
                      Get.toNamed(
                        AppRouteName.CHAT_ROOM_SCREEN,
                        arguments: room.id,
                      );
                    },
                  );
                },
                separatorBuilder: (_, __) => 16.verticalSpace,
                itemCount: rooms.length,
              );
            },
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
