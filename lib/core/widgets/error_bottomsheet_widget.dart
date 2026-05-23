import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ErrorBottomsheetWidget extends StatelessWidget {
  final String ticketId;
  final String message;

  const ErrorBottomsheetWidget({
    super.key,
    required this.ticketId,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            16.verticalSpace,
            Icon(
              Icons.error_outline,
              color: AppColor.primaryColor,
              size: 48.r,
            ),
            16.verticalSpace,
            Text(
              'Ooops!! Terjadi Kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            12.verticalSpace,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w300),
            ),
            20.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
                          ticketId,
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
                      await Clipboard.setData(ClipboardData(text: ticketId));
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
              'Berikan ID tiket ini ke tim teknis agar error bisa dicek pada sistem.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.black54),
            ),
            24.verticalSpace,
            ButtonWidget(
              onPressed: () => Get.back(),
              title: 'Oke',
            ),
          ],
        ),
      ),
    );
  }
}
