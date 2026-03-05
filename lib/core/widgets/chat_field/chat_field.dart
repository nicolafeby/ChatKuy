import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/chat_field/attachment_overlay.dart';
import 'package:chatkuy/core/widgets/chat_field/attachment_sheet.dart';
import 'package:chatkuy/core/helpers/emoji_picker_overlay.dart';
import 'package:chatkuy/core/helpers/imahe_picker_helper.dart';
import 'package:chatkuy/core/helpers/permission_handeler_helper.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/attachment_model.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_attach_image_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatField extends StatelessWidget with BaseLayout {
  final ChatRoomStore store;
  final bool disableAttachment;
  final Function(String text) onSend;

  const ChatField({
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

class ChatFieldV2 extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData sendIcon;
  final Color sendButtonColor;
  final double textFieldRadius;
  final double sendButtonRadius;
  final IconData emojiIcon;
  final IconData attachmentIcon;
  final bool showEmogyIcon;
  final bool showAttachmentIcon;
  final VoidCallback? onSendTap;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final bool autoFocus;
  final int maxLines;
  final AttachmentConfig? attachmentConfig;
  final bool readOnly;
  final bool enabled;
  final bool enableSuggestions;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final Widget? customEmojiIcon;
  final VoidCallback? onCustomEmojiTap;
  final ChatRoomStore store;

  const ChatFieldV2({
    super.key,
    required this.controller,
    this.hintText = 'Tulis pesan...',
    this.sendIcon = Icons.send,
    this.sendButtonColor = Colors.green,
    this.textFieldRadius = 25.0,
    this.sendButtonRadius = 25.0,
    this.emojiIcon = Icons.emoji_emotions_outlined,
    this.attachmentIcon = Icons.attach_file,
    this.showEmogyIcon = true,
    this.showAttachmentIcon = true,
    this.onSendTap,
    this.onChanged,
    this.textInputAction = TextInputAction.send,
    this.keyboardType = TextInputType.multiline,
    this.autoFocus = false,
    this.maxLines = 1,
    this.attachmentConfig,
    this.readOnly = false,
    this.enabled = true,
    this.enableSuggestions = false,
    this.autocorrect = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.customEmojiIcon,
    this.onCustomEmojiTap,
    required this.store,
  });

  @override
  State<ChatFieldV2> createState() => _ChatFieldV2State();

  static bool _isEmojiShowing = false;

  static bool get isEmojiShowing => _isEmojiShowing;

  static void setEmojiShowing(bool value) {
    _isEmojiShowing = value;
  }
}

class _ChatFieldV2State extends State<ChatFieldV2> with WidgetsBindingObserver, BaseLayout {
  bool _showAboveSheet = false;
  bool _showEmojiPicker = false;
  bool isFocused = false;
  final FocusNode _focusNode = FocusNode();
  double? _keyboardHeight = 259.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => didChangeMetrics());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom / View.of(context).devicePixelRatio;

    if (bottomInset > 0 && bottomInset > (_keyboardHeight ?? 0)) {
      setState(() {
        _keyboardHeight = bottomInset;
        if (_showEmojiPicker) {
          _showEmojiPicker = false;
          ChatFieldV2.setEmojiShowing(false);
        }
      });
    }

    if (isFocused && _showEmojiPicker == true) {
      setState(() {
        _showEmojiPicker = false;
        ChatFieldV2.setEmojiShowing(false);
      });
    }
  }

  void _toggleEmojiKeyboard() async {
    if (_showEmojiPicker) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() => _showEmojiPicker = false);
      ChatFieldV2.setEmojiShowing(false);
    } else {
      FocusScope.of(context).unfocus();
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() => _showEmojiPicker = true);
        ChatFieldV2.setEmojiShowing(true);
      }
    }

    setState(() => _showAboveSheet = false);
  }

  void showAttachment(BuildContext context) {
    final options = [
      AttachmentOption(
        icon: Icons.camera_alt,
        label: "Camera",
        onTap: () {
          AttachmentOverlay.hide();
          handlePermission(
            permission: Permission.camera,
            onSuccess: () async {
              dismissLoading();
              final image = await ImagePickerHelper.pickImage(
                source: PickImageSource.camera,
              );

              if (image == null) return;

              Get.toNamed(AppRouteName.CHAT_ATTACH_IMAGE_SCREEN,
                  arguments: ChatAttachImageArgument(image: image, store: widget.store));
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
      ),
      AttachmentOption(
        icon: Icons.photo,
        label: "Gallery",
        onTap: () {
          AttachmentOverlay.hide();
          handlePermission(
            permission: Permission.mediaLibrary,
            onSuccess: () async {
              dismissLoading();
              final image = await ImagePickerHelper.pickImage(
                source: PickImageSource.gallery,
              );

              if (image == null) return;

              Get.toNamed(AppRouteName.CHAT_ATTACH_IMAGE_SCREEN,
                  arguments: ChatAttachImageArgument(image: image, store: widget.store));
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
      ),
      AttachmentOption(
        icon: Icons.description,
        label: "Document",
        onTap: () {
          debugPrint("Document clicked");
          AttachmentOverlay.hide();
        },
      ),
      AttachmentOption(
        icon: Icons.contacts,
        label: "Contact",
        onTap: () {
          debugPrint("Contact clicked");
          AttachmentOverlay.hide();
        },
      ),
      // AttachmentOption(
      //   icon: Icons.audiotrack,
      //   label: "Audio",
      //   onTap: () {
      //     debugPrint("Audio clicked");
      //     AttachmentOverlay.hide();
      //   },
      // ),
    ];

    AttachmentOverlay.show(
      context: context,
      sheet: AttachmentSheet(options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _showEmojiPicker == false && _showAboveSheet == false,
      onPopInvokedWithResult: (didPop, result) {
        if (_showEmojiPicker || _showAboveSheet) {
          setState(() {
            _showEmojiPicker = false;
            _showAboveSheet = false;
          });
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Focus(
                        onFocusChange: (value) {
                          setState(() {
                            isFocused = value;
                          });
                        },
                        child: TextFormField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          maxLines: widget.maxLines,
                          autofocus: widget.autoFocus,
                          keyboardType: widget.keyboardType,
                          textInputAction: widget.textInputAction,
                          onChanged: widget.onChanged,
                          readOnly: widget.readOnly,
                          enabled: widget.enabled,
                          enableSuggestions: widget.enableSuggestions,
                          autocorrect: widget.autocorrect,
                          textCapitalization: widget.textCapitalization,
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(widget.textFieldRadius),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            hintText: widget.hintText,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(widget.textFieldRadius),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: widget.showEmogyIcon
                                ? IconButton(
                                    icon: Icon(
                                      _showEmojiPicker ? Icons.keyboard_alt_outlined : widget.emojiIcon,
                                      color: Colors.grey,
                                    ),
                                    onPressed: _toggleEmojiKeyboard,
                                  )
                                : (widget.customEmojiIcon != null
                                    ? IconButton(
                                        icon: widget.customEmojiIcon!,
                                        onPressed: widget.onCustomEmojiTap,
                                      )
                                    : null),
                            suffixIcon: widget.showAttachmentIcon &&
                                    ((widget.attachmentConfig?.showCamera ?? true) ||
                                        (widget.attachmentConfig?.showGallery ?? true) ||
                                        (widget.attachmentConfig?.showAudio ?? true) ||
                                        (widget.attachmentConfig?.showDoc ?? true) ||
                                        (widget.attachmentConfig?.showContact ?? true))
                                ? IconButton(
                                    icon: Icon(widget.attachmentIcon, color: Colors.grey),
                                    onPressed: () => showAttachment(context),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: widget.sendButtonRadius * 2,
                      height: widget.sendButtonRadius * 2,
                      decoration: BoxDecoration(
                        color: widget.sendButtonColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(widget.sendIcon, color: Colors.white),
                        onPressed: widget.onSendTap,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showEmojiPicker) SizedBox(height: _keyboardHeight ?? 0),
            ],
          ),
          if (_showEmojiPicker)
            EmojiPickerOverlay(
              controller: widget.controller,
              keyboardHeight: _keyboardHeight ?? 0,
            ),
        ],
      ),
    );
  }
}
