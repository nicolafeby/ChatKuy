import 'package:chatkuy/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CallInfoSkeletonView extends StatelessWidget {
  const CallInfoSkeletonView({super.key, required this.rowCount});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    final effectiveRowCount = rowCount.clamp(1, 6);

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 24.h),
      children: [
        18.verticalSpace,
        Center(
          child: SkeletonBlock(
            width: 112.r,
            height: 112.r,
            borderRadius: BorderRadius.circular(56.r),
          ),
        ),
        16.verticalSpace,
        Center(
          child: SkeletonBlock(
            width: 168.w,
            height: 24.h,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        10.verticalSpace,
        Center(
          child: SkeletonBlock(
            width: 96.w,
            height: 14.h,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        24.verticalSpace,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 12.w),
                  child: const _CallInfoActionSkeleton(),
                ),
              ),
            ),
          ),
        ),
        28.verticalSpace,
        Divider(height: 1.h),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 8.h),
          child: SkeletonBlock(
            width: 86.w,
            height: 16.h,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        ...List.generate(
          effectiveRowCount,
          (index) => ListTile(
            enabled: false,
            leading: SkeletonBlock(
              width: 24.r,
              height: 24.r,
              borderRadius: BorderRadius.circular(12.r),
            ),
            title: Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBlock(
                width: index.isEven ? 112.w : 88.w,
                height: 14.h,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: SkeletonBlock(
                width: 64.w,
                height: 12.h,
                borderRadius: BorderRadius.circular(7.r),
              ),
            ),
            trailing: SkeletonBlock(
              width: 72.w,
              height: 14.h,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
      ],
    );
  }
}

class _CallInfoActionSkeleton extends StatelessWidget {
  const _CallInfoActionSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 82.h,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonBlock(
            width: 24.r,
            height: 24.r,
            borderRadius: BorderRadius.circular(12.r),
          ),
          10.verticalSpace,
          SkeletonBlock(
            width: 48.w,
            height: 12.h,
            borderRadius: BorderRadius.circular(7.r),
          ),
        ],
      ),
    );
  }
}
