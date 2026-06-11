import 'dart:io';
import 'package:chatkuy/core/helpers/image_cropper_helper.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChatAttachImageArgument {
  const ChatAttachImageArgument({required this.image, required this.store});

  final File image;
  final ChatRoomStore store;
}

class ChatAttachImageScreen extends StatefulWidget {
  const ChatAttachImageScreen({super.key});

  @override
  State<ChatAttachImageScreen> createState() => _ChatAttachImageScreenState();
}

class _ChatAttachImageScreenState extends State<ChatAttachImageScreen> {
  ChatAttachImageArgument? argument;

  @override
  void initState() {
    super.initState();
    argument = Get.arguments as ChatAttachImageArgument?;
    argument?.store.croppedImage = null;
  }

  @override
  Widget build(BuildContext context) {
    final image = argument?.image;
    if (image == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Observer(
        builder: (context) => Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: Image.file(
                    argument?.store.croppedImage ?? image,
                    fit: BoxFit.contain,
                    width: 1.sw,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(bottom: false, child: _buildHeaderButton()),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _AttachCaptionBar(
                store: argument!.store,
                onSend: _sendImage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendImage() {
    final image = argument?.store.croppedImage ?? argument?.image;
    if (image == null) return;

    argument?.store.sendMessage(
      argument!.store.messageController.text.trim(),
      image,
    );
    argument?.store.messageController.clear();
    Get.back();
  }

  Widget _buildHeaderButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          _PreviewIconButton(icon: Icons.close, onTap: () => Get.back()),
          const Spacer(),
          _PreviewIconButton(icon: Icons.crop_rotate, onTap: _cropImage),
        ],
      ),
    );
  }

  Future<void> _cropImage() async {
    final croppedImage = await ImageCropperHelper.cropImage(
      imageFile: argument!.store.croppedImage ?? argument!.image,
    );

    if (croppedImage == null) return;
    argument?.store.croppedImage = croppedImage;
  }
}

class _AttachCaptionBar extends StatelessWidget {
  const _AttachCaptionBar({
    required this.store,
    required this.onSend,
  });

  final ChatRoomStore store;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 22.h, 12.w, 8.h),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxHeight: 122.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: TextField(
                  controller: store.messageController,
                  onChanged: store.onTypingChanged,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: Colors.white, fontSize: 15.sp),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppTranslationKey.message.tr,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              ),
            ),
            10.horizontalSpace,
            SizedBox(
              width: 48.r,
              height: 48.r,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: onSend,
                icon: Icon(Icons.send, size: 22.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewIconButton extends StatelessWidget {
  const _PreviewIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 22.r),
    );
  }
}
