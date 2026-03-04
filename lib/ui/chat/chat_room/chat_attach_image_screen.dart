import 'dart:io';
import 'package:chatkuy/core/helpers/image_cropper_helper.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_keyboard_widget.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final image = argument?.image;
    if (image == null) return SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Observer(
        builder: (context) => SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Image.file(
                  argument?.store.croppedImage ?? image,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeaderButton(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildKeyboardSections(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardSections() {
    return ChatKeyboardWidget(
      store: argument!.store,
      disableAttachment: true,
      onSend: (text) {
        final image = (argument?.store.croppedImage ?? argument?.image);
        if (image == null) return;
        argument?.store.sendMessage(text, image);
        argument?.store.messageController.clear();
        Get.back();
      },
    );
  }

  Widget _buildHeaderButton() {
    Widget buildIcon({required IconData icons, required Function() onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.65),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icons,
            color: Colors.white,
            size: 20.r,
          ),
        ),
      );
    }

    return SizedBox(
      width: 1.sw,
      child: Row(
        children: [
          buildIcon(icons: Icons.close, onTap: () => Get.back()),
          Spacer(),
          Row(
            children: [
              buildIcon(icons: Icons.crop, onTap: _cropImage),
              8.horizontalSpace,
              buildIcon(icons: Icons.hd_outlined, onTap: () {}),
            ],
          ),
        ],
      ).paddingAll(20.r),
    );
  }

  Future _cropImage() async {
    final croppedImage = await ImageCropperHelper.cropImage(imageFile: argument!.image);

    if (croppedImage == null) return;
    argument?.store.croppedImage = croppedImage;
  }
}
