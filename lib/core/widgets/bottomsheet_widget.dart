import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class BottomsheetWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final String? asset;
  final bool? restricBackNative;
  final String? errorTicketId;
  const BottomsheetWidget({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Oke',
    this.onButtonPressed,
    this.asset,
    this.restricBackNative = false,
    this.errorTicketId,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedErrorTicketId = errorTicketId;

    return PopScope(
      canPop: !restricBackNative!,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            16.verticalSpace,
            Visibility(
              visible: asset == null ? false : true,
              child: Image.asset(asset ?? '', height: 100.r)
                  .paddingOnly(bottom: 32.h),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            16.verticalSpace,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w300),
            ),
            Visibility(
              visible: resolvedErrorTicketId != null,
              child: Column(
                children: [
                  20.verticalSpace,
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColor.whiteBlue,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColor.primaryDisabled),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID tiket error',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.black54,
                                ),
                              ),
                              4.verticalSpace,
                              SelectableText(
                                resolvedErrorTicketId ?? '',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Salin ID tiket',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: resolvedErrorTicketId ?? ''),
                            );
                            if (Get.isSnackbarOpen) return;
                            Get.showSnackbar(
                              const GetSnackBar(
                                message: 'ID tiket error berhasil disalin',
                                duration: Duration(milliseconds: 1600),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          color: AppColor.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  12.verticalSpace,
                  Text(
                    'Berikan ID tiket ini ke tim teknis agar error bisa dicek pada sistem',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                  ),
                ],
              ),
            ),
            32.verticalSpace,
            ButtonWidget(
                onPressed: onButtonPressed ?? () => Get.back(),
                title: buttonText!)
          ],
        ),
      ),
    );
  }
}
