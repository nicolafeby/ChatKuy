import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/utils.dart';

enum UiMessageStatus {
  sent,
  delivered,
  read,
}

class ChatBubbleWidget extends StatelessWidget {
  const ChatBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.onRetry,
  });

  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: message.status == MessageStatus.failed ? onRetry : null,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColor.primaryColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14.sp,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        message.createdAt.hhmm,
                        style: TextStyle(color: isMe ? Colors.white70 : Colors.black45, fontSize: 10.sp),
                      ),
                      Visibility(
                        visible: isMe ? true : false,
                        child: _buildStatusIcon().paddingOnly(left: 8.w),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // STATUS ICON (WHATSAPP STYLE)
  // -----------------------------
  Widget _buildStatusIcon() {
    // ❗ gagal kirim
    if (message.status == MessageStatus.failed) {
      return Icon(Icons.error, size: 12.sp, color: Colors.redAccent);
    }

    // ⏳ pending (local write)
    if (message.status == MessageStatus.pending) {
      return Icon(Icons.access_time, size: 12.sp, color: Colors.white70);
    }

    // setelah SENT, pakai delivered/read map
    final uiStatus = _resolveUiStatus();

    switch (uiStatus) {
      case UiMessageStatus.sent:
        return Icon(Icons.check, size: 12.sp, color: Colors.white70);

      case UiMessageStatus.delivered:
        return Icon(Icons.done_all, size: 12.sp, color: Colors.white70);

      case UiMessageStatus.read:
        return Icon(Icons.done_all, size: 12.sp, color: Colors.greenAccent);
    }
  }

  // -----------------------------
  // HITUNG STATUS UI
  // -----------------------------
  UiMessageStatus _resolveUiStatus() {
    // ⚠️ asumsi: 1-on-1 chat
    // delivered/read dihitung terhadap lawan chat
    if (message.deliveredTo.isEmpty) {
      return UiMessageStatus.sent;
    }

    // ada delivered tapi belum read
    if (message.readBy.isEmpty) {
      return UiMessageStatus.delivered;
    }

    // sudah dibaca
    return UiMessageStatus.read;
  }
}
