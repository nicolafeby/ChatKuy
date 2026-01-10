import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatKeyboardWidget extends StatelessWidget {
  final ChatRoomStore store;
  const ChatKeyboardWidget({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.r, horizontal: 16.r),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 0.75.sw,
              child: TextField(
                minLines: 1,
                cursorHeight: 18.r,
                controller: store.messageController,
                textInputAction: TextInputAction.newline,
                maxLines: 5,
                decoration: InputDecoration(
                  prefixIcon: InkWell(
                    radius: 10,
                    borderRadius: BorderRadius.circular(50.r),
                    onTap: () {},
                    child: Icon(Icons.attach_file),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  hintText: "Tulis pesan ....",
                ),
              ),
            ),
            Spacer(),
            Container(
              decoration: BoxDecoration(color: AppColor.primaryColor, shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(
                  Icons.send_outlined,
                  color: Colors.white,
                ),
                onPressed: () => store.sendMessage(store.messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
