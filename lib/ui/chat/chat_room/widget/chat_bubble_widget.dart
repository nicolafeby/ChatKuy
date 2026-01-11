import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap:
                message.status == MessageStatus.failed ? onRetry : null,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color:
                          isMe ? Colors.white : Colors.black87,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (isMe) ...[
                    4.verticalSpace,
                    _buildStatusIcon(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.pending:
        return Icon(Icons.access_time,
            size: 12.sp, color: Colors.white70);
      case MessageStatus.sent:
        return Icon(Icons.check,
            size: 12.sp, color: Colors.white70);
      case MessageStatus.failed:
        return Icon(Icons.error,
            size: 12.sp, color: Colors.redAccent);
    }
  }
}
