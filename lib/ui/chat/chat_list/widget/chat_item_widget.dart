import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/data/models/chat_user_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatItemWidget extends StatelessWidget {
  final VoidCallback onTap;
  final ChatUserItemModel user;
  const ChatItemWidget({
    super.key,
    required this.onTap,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 16.r),
        color: Colors.white,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100.r),
              child: CachedNetworkImage(
                height: 50.r,
                width: 50.r,
                imageUrl: AppStrings.dummyNetworkImage,
              ),
            ),
            16.horizontalSpace,
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user.user.name,
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      Text(
                        user.lastMessageAt?.hhmm ?? '-',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                  Text(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    user.lastMessage ?? '-',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
