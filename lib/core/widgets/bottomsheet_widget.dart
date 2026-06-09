import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/utils/error_ticket_visibility.dart';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
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
    this.buttonText,
    this.onButtonPressed,
    this.asset,
    this.restricBackNative = false,
    this.errorTicketId,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedErrorTicketId = ErrorTicketVisibility.visibleTicketId(
      ticketId: errorTicketId,
      message: message,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !restricBackNative!,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: colorScheme.surface,
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
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            16.verticalSpace,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w300,
                color: colorScheme.onSurfaceVariant,
              ),
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
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslationKey.errorTicketId.tr,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              4.verticalSpace,
                              SelectableText(
                                resolvedErrorTicketId ?? '',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: AppTranslationKey.copyTicketId.tr,
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: resolvedErrorTicketId ?? ''),
                            );
                            if (Get.isSnackbarOpen) return;
                            Get.showSnackbar(
                              GetSnackBar(
                                message: AppTranslationKey.errorTicketCopied.tr,
                                duration: const Duration(milliseconds: 1600),
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
                    AppTranslationKey.errorTicketHelp.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            32.verticalSpace,
            ButtonWidget(
                onPressed: onButtonPressed ?? () => Get.back(),
                title: buttonText ?? AppTranslationKey.ok.tr)
          ],
        ),
      ),
    );
  }
}
