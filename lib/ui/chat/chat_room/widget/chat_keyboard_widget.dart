import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/helpers/imahe_picker_helper.dart';
import 'package:chatkuy/core/helpers/permission_handeler_helper.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_attach_image_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatKeyboardWidget extends StatelessWidget with BaseLayout {
  final ChatRoomStore store;
  final bool disableAttachment;
  final Function(String text) onSend;

  const ChatKeyboardWidget({
    super.key,
    required this.store,
    this.disableAttachment = false,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6).r,
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_emotions_outlined, size: 22.r),
                    8.horizontalSpace,
                    Expanded(
                      child: TextField(
                        controller: store.messageController,
                        onChanged: store.onTypingChanged,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Message",
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: !disableAttachment,
                      child: GestureDetector(
                        onTap: () {
                          handlePermission(
                            permission: Permission.mediaLibrary,
                            onSuccess: () async {
                              dismissLoading();
                              final image = await ImagePickerHelper.pickImage(
                                source: PickImageSource.gallery,
                              );

                              if (image == null) return;

                              Get.toNamed(AppRouteName.CHAT_ATTACH_IMAGE_SCREEN,
                                  arguments: ChatAttachImageArgument(image: image, store: store));
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
                        child: Icon(Icons.attach_file, size: 22.r),
                      ),
                    ),
                    Visibility(
                      visible: !disableAttachment,
                      child: GestureDetector(
                        onTap: () {
                          handlePermission(
                            permission: Permission.camera,
                            onSuccess: () async {
                              dismissLoading();
                              final image = await ImagePickerHelper.pickImage(
                                source: PickImageSource.camera,
                              );

                              if (image == null) return;

                              Get.toNamed(AppRouteName.CHAT_ATTACH_IMAGE_SCREEN,
                                  arguments: ChatAttachImageArgument(image: image, store: store));
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
                        child: Icon(Icons.camera_alt, size: 22.r).paddingOnly(left: 8.w),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            6.horizontalSpace,
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.green,
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white, size: 20.r),
                onPressed: () => onSend.call(store.messageController.text.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
