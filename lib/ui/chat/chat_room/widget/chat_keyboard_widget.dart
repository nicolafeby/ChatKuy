import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/core/helpers/image_cropper_helper.dart';
import 'package:chatkuy/core/helpers/imahe_picker_helper.dart';
import 'package:chatkuy/core/helpers/permission_handeler_helper.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatKeyboardWidget extends StatelessWidget with BaseLayout {
  final ChatRoomStore store;
  const ChatKeyboardWidget({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.r, horizontal: 16.r),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 0.75.sw,
              child: TextField(
                minLines: 1,
                cursorHeight: 18.r,
                controller: store.messageController,
                textInputAction: TextInputAction.newline,
                maxLines: 5,
                onChanged: store.onTypingChanged,
                decoration: InputDecoration(
                  prefixIcon: InkWell(
                    radius: 10,
                    borderRadius: BorderRadius.circular(50.r),
                    onTap: _pickImage,
                    child: Icon(Icons.attach_file),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  hintText: "Tulis pesan ....",
                ),
              ),
            ),
            Spacer(),
            Container(
              decoration: BoxDecoration(color: AppColor.primaryColor, shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(
                  Icons.send_outlined,
                  color: Colors.white,
                ),
                onPressed: () => store.sendMessage(store.messageController.text.trim(), store.pickedImage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage() {
    Get.dialog(Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 60.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pilih Opsi',
            style: TextStyle(fontSize: 18.sp),
          ),
          10.verticalSpace,
          TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 6.r),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              handlePermission(
                permission: Permission.mediaLibrary,
                onSuccess: () async {
                  dismissLoading();
                  final image = await ImagePickerHelper.pickImage(
                    source: PickImageSource.gallery,
                  );

                  if (image == null) return;
                  final croppedImage = await ImageCropperHelper.cropImage(imageFile: image);

                  store.pickedImage = croppedImage;

                  // if (croppedImage == null) return;
                  // final base64 = await FileConverterHelper.fileToBase64(croppedImage);
                },
                onDenied: (p0) {
                  Get.bottomSheet(BottomsheetWidget(
                    asset: AppAsset.imgFaceSad,
                    title: AppStrings.oopsTerjadiKesalahan,
                    message: 'Kami tidak mendapatkan akses galeri untuk action ini',
                  ));
                },
              );
            },
            label: Text(
              'Pilih dari galeri',
              style: TextStyle(fontSize: 16.sp),
            ),
            icon: Icon(Icons.photo_album_outlined),
          ),
          2.verticalSpace,
          TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 6.r),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              handlePermission(
                permission: Permission.camera,
                onSuccess: () async {
                  dismissLoading();
                  final image = await ImagePickerHelper.pickImage(
                    source: PickImageSource.camera,
                  );

                  if (image == null) return;
                  final croppedImage = await ImageCropperHelper.cropImage(imageFile: image);

                  store.pickedImage = croppedImage;

                  // if (croppedImage == null) return;
                  // final base64 = await FileConverterHelper.fileToBase64(croppedImage);
                },
                onDenied: (p0) {
                  Get.bottomSheet(BottomsheetWidget(
                    asset: AppAsset.imgFaceSad,
                    title: AppStrings.oopsTerjadiKesalahan,
                    message: 'Kami tidak mendapatkan akses kamera untuk action ini',
                  ));
                },
              );
            },
            label: Text(
              'Ambil dari kamera',
              style: TextStyle(fontSize: 16.sp),
            ),
            icon: Icon(Icons.camera_alt_outlined),
          ),
        ],
      ).paddingOnly(top: 12.h, bottom: 8.h),
    ));
  }
}
