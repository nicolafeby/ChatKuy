import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    this.isFirstInGroup = true,
    this.isSameGroup = false,
  });

  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onRetry;

  final bool isFirstInGroup;
  final bool isSameGroup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isSameGroup ? 1.5.h : 8.h,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: GestureDetector(
              onTap: message.status == MessageStatus.failed ? onRetry : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppColor.primaryColor.withOpacity(0.8) : Colors.grey.shade200,
                  borderRadius: _bubbleRadius(),
                ),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius _bubbleRadius() {
    final r = Radius.circular(8.r);

    return BorderRadius.only(
      topLeft: isMe ? r : (isSameGroup ? r : Radius.zero),
      topRight: isMe ? (isSameGroup ? r : Radius.zero) : r,
      bottomLeft: r,
      bottomRight: r,
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.text,
          softWrap: true,
          textAlign: TextAlign.left,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14.sp,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6.w,
          children: [
            Text(
              message.createdAt.hhmm,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black45,
                fontSize: 10.sp,
              ),
            ),
            if (isMe) _buildStatusIcon(),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    if (message.status == MessageStatus.failed) {
      return Icon(
        Icons.error,
        size: 12.sp,
        color: Colors.redAccent,
      );
    }

    if (message.status == MessageStatus.pending) {
      return Icon(
        Icons.access_time,
        size: 12.sp,
        color: Colors.white70,
      );
    }

    final uiStatus = _resolveUiStatus();

    switch (uiStatus) {
      case UiMessageStatus.sent:
        return Icon(
          Icons.check,
          size: 12.sp,
          color: Colors.white70,
        );

      case UiMessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 12.sp,
          color: Colors.white70,
        );

      case UiMessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 12.sp,
          color: Colors.yellowAccent,
        );
    }
  }

  UiMessageStatus _resolveUiStatus() {
    if (message.deliveredTo.isEmpty) {
      return UiMessageStatus.sent;
    }

    if (message.readBy.isEmpty) {
      return UiMessageStatus.delivered;
    }

    return UiMessageStatus.read;
  }
}
