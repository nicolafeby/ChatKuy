import 'dart:io';

import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/widgets/image_viewer_widget.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
    this.uploadProgress,
    this.isFirstInGroup = true,
    this.isSameGroup = false,
  });

  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onRetry;
  final int? uploadProgress;

  final bool isFirstInGroup;
  final bool isSameGroup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isSameGroup ? 1.5.h : 8.h,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                  color: isMe
                      ? AppColor.primaryColor.withOpacity(0.8)
                      : Colors.grey.shade200,
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
    final type = message.type;
    final imageUrl = message.imageUrl;
    final localImagePath = message.localImagePath;
    final hasImage = type == MessageType.image &&
        (localImagePath != null || imageUrl != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasImage) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: imageUrl == null
                    ? null
                    : () => Get.toNamed(
                          AppRouteName.IMAGE_VIEWER_SCREEN,
                          arguments: ImageViewerArgument(imageUrl: imageUrl),
                        ),
                child: Hero(
                  tag: imageUrl ?? message.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: _buildImagePreview(
                      imageUrl: imageUrl,
                      localImagePath: localImagePath,
                    ),
                  ),
                ),
              ),
              4.verticalSpace,
              Visibility(
                visible: message.text?.isNotEmpty == true,
                child: Text(
                  message.text ?? '',
                  softWrap: true,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          )
        ] else ...[
          Text(
            message.text ?? '',
            softWrap: true,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 14.sp,
            ),
          ),
        ],
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

  Widget _buildImagePreview({
    required String? imageUrl,
    required String? localImagePath,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (localImagePath != null)
          Image.file(
            File(localImagePath),
            height: 200.h,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildBrokenImage(),
          )
        else if (imageUrl != null)
          Image.network(
            height: 200.h,
            width: double.infinity,
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildImageLoading();
            },
            errorBuilder: (context, error, stackTrace) => _buildBrokenImage(),
          )
        else
          _buildBrokenImage(),
        if (message.status == MessageStatus.pending)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: _buildUploadProgress(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    final progress = uploadProgress?.clamp(0, 100);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 42.r,
          height: 42.r,
          child: CircularProgressIndicator(
            value: progress == null ? null : progress / 100,
            color: Colors.white,
            backgroundColor: Colors.white24,
            strokeWidth: 3,
          ),
        ),
        if (progress != null) ...[
          8.verticalSpace,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              '$progress%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageLoading() {
    return Container(
      height: 200.h,
      width: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildBrokenImage() {
    return Container(
      height: 200.h,
      width: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image,
        size: 48,
        color: Colors.grey,
      ),
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
