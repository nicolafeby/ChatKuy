import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatKeyboardWidget extends StatelessWidget {
  final ChatRoomStore store;
  const ChatKeyboardWidget({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.r),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 42.h,
              width: 0.81.sw,
              child: TextField(
                cursorHeight: 18.r,
                controller: store.messageController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  hintText: "Tulis pesan ....",
                ),
              ),
            ).paddingOnly(left: 16.w),
            Spacer(),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: store.sendMessage,
            ).paddingOnly(right: 2.w),
          ],
        ),
      ),
    );
  }
}
