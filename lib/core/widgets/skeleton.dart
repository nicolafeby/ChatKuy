import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF1F2C33) : const Color(0xFFD4DBDF);
    final highlightColor =
        isDark ? const Color(0xFF2A3942) : const Color(0xFFF0F2F5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final color = Color.lerp(
          baseColor,
          highlightColor,
          _animation.value,
        )!;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8.r),
          ),
          child: child,
        );
      },
      child: SizedBox(width: widget.width, height: widget.height),
    );
  }
}

class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({
    super.key,
    this.index = 0,
    this.leadingSize = 48,
    this.trailingSize = 32,
    this.showSubtitleIcon = true,
    this.showTrailing = true,
  });

  final int index;
  final double leadingSize;
  final double trailingSize;
  final bool showSubtitleIcon;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    final titleWidth = index.isEven ? 148.w : 112.w;
    final subtitleWidth = index % 3 == 0 ? 126.w : 92.w;

    return ListTile(
      enabled: false,
      leading: SkeletonBlock(
        width: leadingSize.r,
        height: leadingSize.r,
        borderRadius: BorderRadius.circular((leadingSize / 2).r),
      ),
      title: Align(
        alignment: Alignment.centerLeft,
        child: SkeletonBlock(
          width: titleWidth,
          height: 14.h,
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Row(
          children: [
            if (showSubtitleIcon) ...[
              SkeletonBlock(
                width: 16.r,
                height: 16.r,
                borderRadius: BorderRadius.circular(8.r),
              ),
              6.horizontalSpace,
            ],
            SkeletonBlock(
              width: subtitleWidth,
              height: 12.h,
              borderRadius: BorderRadius.circular(7.r),
            ),
          ],
        ),
      ),
      trailing: showTrailing
          ? SkeletonBlock(
              width: trailingSize.r,
              height: trailingSize.r,
              borderRadius: BorderRadius.circular((trailingSize / 2).r),
            )
          : null,
    );
  }
}

class ListTileSkeletonList extends StatelessWidget {
  const ListTileSkeletonList({
    super.key,
    this.itemCount = 8,
    this.padding,
    this.showSubtitleIcon = true,
    this.showTrailing = true,
  });

  final int itemCount;
  final EdgeInsetsGeometry? padding;
  final bool showSubtitleIcon;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.only(top: 8.h, bottom: 16.h),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 2.h),
      itemBuilder: (_, index) => ListTileSkeleton(
        index: index,
        showSubtitleIcon: showSubtitleIcon,
        showTrailing: showTrailing,
      ),
    );
  }
}

class ChatRoomSkeletonView extends StatelessWidget {
  const ChatRoomSkeletonView({
    super.key,
    this.itemCount = 9,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.r),
      reverse: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final isMe = index.isEven;
        final hasMedia = index % 5 == 0;
        final bubbleWidth = hasMedia ? 220.w : (index % 3 == 0 ? 184.w : 132.w);

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(top: index == itemCount - 1 ? 0 : 8.h),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasMedia)
                  SkeletonBlock(
                    width: bubbleWidth,
                    height: 142.h,
                    borderRadius: BorderRadius.circular(8.r),
                  )
                else
                  SkeletonBlock(
                    width: bubbleWidth,
                    height: 42.h,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMe ? 8.r : 2.r),
                      topRight: Radius.circular(isMe ? 2.r : 8.r),
                      bottomLeft: Radius.circular(8.r),
                      bottomRight: Radius.circular(8.r),
                    ),
                  ),
                4.verticalSpace,
                SkeletonBlock(
                  width: 42.w,
                  height: 9.h,
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CardListTileSkeletonList extends StatelessWidget {
  const CardListTileSkeletonList({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.all(16),
    this.showActions = true,
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, index) {
        return Card(
          child: ListTileSkeleton(
            index: index,
            showSubtitleIcon: false,
            showTrailing: showActions,
            trailingSize: 56,
          ),
        );
      },
    );
  }
}

class ProfileSkeletonView extends StatelessWidget {
  const ProfileSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          expandedHeight: 200.h,
          pinned: true,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50.r),
                  bottomRight: Radius.circular(50.r),
                ),
              ),
              padding: const EdgeInsets.only(top: 50),
              child: Column(
                children: [
                  24.verticalSpace,
                  SkeletonBlock(
                    width: 88.r,
                    height: 88.r,
                    borderRadius: BorderRadius.circular(44.r),
                  ),
                  12.verticalSpace,
                  SkeletonBlock(width: 132.w, height: 18.h),
                  10.verticalSpace,
                  SkeletonBlock(width: 92.w, height: 14.h),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    3,
                    (index) => Column(
                      children: [
                        SkeletonBlock(
                          width: 48.r,
                          height: 48.r,
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        8.verticalSpace,
                        SkeletonBlock(width: 56.w, height: 12.h),
                      ],
                    ),
                  ),
                ),
                28.verticalSpace,
                Align(
                  alignment: Alignment.centerLeft,
                  child: SkeletonBlock(width: 150.w, height: 18.h),
                ),
                16.verticalSpace,
                ...List.generate(
                  6,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Row(
                      children: [
                        SkeletonBlock(
                          width: 36.r,
                          height: 36.r,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBlock(width: 92.w, height: 12.h),
                              8.verticalSpace,
                              SkeletonBlock(
                                width: index.isEven ? 180.w : 132.w,
                                height: 14.h,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
