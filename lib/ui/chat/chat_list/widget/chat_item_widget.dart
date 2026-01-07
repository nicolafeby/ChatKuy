import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatItemWidget extends StatelessWidget {
  const ChatItemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100.r),
          child: CachedNetworkImage(
            height: 50.r,
            width: 50.r,
            imageUrl: 'https://dummyimage.com/300',
          ),
        ),
        16.horizontalSpace,
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smith Mathew',
                style: TextStyle(fontSize: 16.sp),
              ),
              Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Hope you’re doing well today Hope you’re doing well today..',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
            ],
          ),
        )
      ],
    );
  }
}
