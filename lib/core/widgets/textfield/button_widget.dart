import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/stores/button/button_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/widget_extensions.dart';

enum CountdownUnit { seconds, minutes }

class ButtonWidget extends StatefulWidget {
  final VoidCallback? onPressed;
  final String title;

  const ButtonWidget({
    super.key,
    required this.onPressed,
    required this.title,
  });

  static Widget withCountdown({
    required VoidCallback onPressed,
    String? title,
    String? titleAfterButtonClicked,
    required int value,
    CountdownUnit unit = CountdownUnit.seconds,
    bool? initCountdown,
  }) {
    return _CountdownButton(
      onPressed: onPressed,
      title: title,
      value: value,
      unit: unit,
      titleAfterButtonClicked: titleAfterButtonClicked,
      initCountdown: initCountdown,
    );
  }

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: widget.onPressed == null
            ? null
            : () {
                FocusManager.instance.primaryFocus?.unfocus();
                widget.onPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: AppColor.primaryDisabled,
          backgroundColor: AppColor.primaryColor,
          elevation: 0.0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
      ),
    );
  }
}

class _CountdownButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String? title;
  final String? titleAfterButtonClicked;
  final int value;
  final CountdownUnit unit;
  final bool? initCountdown;

  const _CountdownButton({
    required this.onPressed,
    this.title,
    this.titleAfterButtonClicked,
    required this.value,
    required this.unit,
    this.initCountdown = false,
  });

  @override
  State<_CountdownButton> createState() => _CountdownButtonState();
}

class _CountdownButtonState extends State<_CountdownButton> {
  final ButtonStore store = ButtonStore();

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initCountdown == true) _handlePressed();
  }

  void _handlePressed() {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onPressed();
    store.startCountdown(
      value: widget.value,
      unit: widget.unit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: Observer(
        builder: (_) {
          return ElevatedButton(
            onPressed: (store.isDisabled) ? null : _handlePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primaryColor,
              disabledBackgroundColor: AppColor.primaryDisabled,
              elevation: 0.0,
              shadowColor: Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.title != null)
                  Text(
                    store.isButtonClicked ? (widget.titleAfterButtonClicked ?? widget.title!) : widget.title!,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18.sp,
                    ),
                  ).paddingOnly(right: store.isDisabled ? 8.w : 0),
                if (store.isDisabled)
                  Text(
                    '(${store.formattedTime})',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
