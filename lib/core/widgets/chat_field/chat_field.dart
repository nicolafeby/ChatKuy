import 'dart:async';
import 'dart:io';

import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/asset.dart';
import 'package:chatkuy/core/constants/routes.dart';
import 'package:chatkuy/core/widgets/chat_field/attachment_overlay.dart';
import 'package:chatkuy/core/widgets/chat_field/attachment_sheet.dart';
import 'package:chatkuy/core/helpers/contact_picker_dialgue.dart';
import 'package:chatkuy/core/helpers/emoji_picker_overlay.dart';
import 'package:chatkuy/core/helpers/imahe_picker_helper.dart';
import 'package:chatkuy/core/helpers/permission_handeler_helper.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/core/widgets/bottomsheet_widget.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/attachment_model.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_attach_image_screen.dart';
import 'package:chatkuy/ui/chat/chat_room/chat_attach_video_screen.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

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
    final colorScheme = colorSchemeOf(context);
    final isDarkMode = isDarkModeOf(context);
    final fieldColor = isDarkMode ? const Color(0xFF18232C) : Colors.grey.shade200;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6).r,
        color: colorScheme.surface,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.h),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_emotions_outlined,
                      size: 22.r,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: TextField(
                        controller: store.messageController,
                        onChanged: store.onTypingChanged,
                        minLines: 1,
                        maxLines: 5,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: AppTranslationKey.message.tr,
                          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
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
                                message: AppTranslationKey.galleryPermissionDenied.tr,
                              ));
                            },
                          );
                        },
                        child: Icon(
                          Icons.attach_file,
                          size: 22.r,
                          color: colorScheme.onSurfaceVariant,
                        ),
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
                                message: AppTranslationKey.cameraPermissionDenied.tr,
                              ));
                            },
                          );
                        },
                        child: Icon(
                          Icons.camera_alt,
                          size: 22.r,
                          color: colorScheme.onSurfaceVariant,
                        ).paddingOnly(left: 8.w),
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
    this.hintText = 'writeMessage',
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
    this.textInputAction = TextInputAction.newline,
    this.keyboardType = TextInputType.multiline,
    this.autoFocus = false,
    this.maxLines = 5,
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
  bool _isRecording = false;
  bool _hasText = false;
  bool isFocused = false;
  final FocusNode _focusNode = FocusNode();
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;
  DateTime? _recordingStartedAt;
  File? _recordingFile;
  Duration _recordingDuration = Duration.zero;
  double? _keyboardHeight = 259.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_handleTextControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => didChangeMetrics());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_handleTextControllerChanged);
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextControllerChanged() {
    final nextHasText = widget.controller.text.trim().isNotEmpty;
    if (nextHasText == _hasText) return;

    setState(() {
      _hasText = nextHasText;
    });
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
      if (!mounted) return;
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

    if (!mounted) return;
    setState(() => _showAboveSheet = false);
  }

  void showAttachment(BuildContext context) {
    final options = [
      AttachmentOption(
        icon: Icons.camera_alt,
        label: AppTranslationKey.camera.tr,
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
                message: AppTranslationKey.cameraPermissionDenied.tr,
              ));
            },
          );
        },
      ),
      AttachmentOption(
        icon: Icons.photo,
        label: AppTranslationKey.gallery.tr,
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
                message: AppTranslationKey.galleryPermissionDenied.tr,
              ));
            },
          );
        },
      ),
      AttachmentOption(
        icon: Icons.videocam,
        label: AppTranslationKey.video.tr,
        onTap: () {
          AttachmentOverlay.hide();
          handlePermission(
            permission: Permission.mediaLibrary,
            onSuccess: () async {
              dismissLoading();
              final video = await ImagePickerHelper.pickVideo(
                source: PickImageSource.gallery,
              );

              if (video == null) return;

              Get.toNamed(
                AppRouteName.CHAT_ATTACH_VIDEO_SCREEN,
                arguments: ChatAttachVideoArgument(
                  video: video,
                  store: widget.store,
                ),
              );
            },
            onDenied: (p0) {
              Get.bottomSheet(BottomsheetWidget(
                asset: AppAsset.imgFaceSad,
                title: AppStrings.oopsTerjadiKesalahan,
                message: AppTranslationKey.galleryPermissionDenied.tr,
              ));
            },
          );
        },
      ),
      AttachmentOption(
        icon: Icons.description,
        label: AppTranslationKey.document.tr,
        onTap: () async {
          AttachmentOverlay.hide();
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            type: FileType.any,
            withData: false,
          );

          final path = result?.files.single.path;
          if (path == null) return;

          try {
            await widget.store.sendFileMessage(File(path));
          } catch (_) {
            Get.snackbar(
              AppTranslationKey.chat.tr,
              AppTranslationKey.documentSendFailed.tr,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
      ),
      AttachmentOption(
        icon: Icons.contacts,
        label: AppTranslationKey.contact.tr,
        onTap: () async {
          AttachmentOverlay.hide();
          final hasPermission = await FlutterContacts.requestPermission(
            readonly: true,
          );

          if (!hasPermission) {
            Get.bottomSheet(BottomsheetWidget(
              asset: AppAsset.imgFaceSad,
              title: AppStrings.oopsTerjadiKesalahan,
              message: AppTranslationKey.contactPermissionDenied.tr,
            ));
            return;
          }

          final contacts = await FlutterContacts.getContacts(
            withProperties: true,
            withPhoto: true,
          );

          if (!context.mounted) return;

          showDialog<void>(
            context: context,
            builder: (context) => ContactPickerDialog(
              contacts: contacts.where((contact) => contact.phones.isNotEmpty),
              onContactSelect: (contact) async {
                final phones = contact['phones'];
                final phone = phones is List && phones.isNotEmpty ? phones.first['number']?.toString() : null;
                if (phone == null || phone.trim().isEmpty) return;

                try {
                  await widget.store.sendContactMessage(
                    name: contact['displayName']?.toString() ?? AppTranslationKey.contact.tr,
                    phone: phone,
                  );
                } catch (_) {
                  Get.snackbar(
                    AppTranslationKey.chat.tr,
                    AppTranslationKey.contactSendFailed.tr,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
          );
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

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopAndSendRecording();
      return;
    }

    await _startRecording();
  }

  Future<void> _startRecording() async {
    FocusScope.of(context).unfocus();

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      Get.bottomSheet(BottomsheetWidget(
        asset: AppAsset.imgFaceSad,
        title: AppStrings.oopsTerjadiKesalahan,
        message: AppTranslationKey.microphonePermissionDenied.tr,
      ));
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return;

    final file = await widget.store.createAudioRecordingFile();
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: file.path,
    );

    _recordingTimer?.cancel();
    _recordingStartedAt = DateTime.now();
    _recordingFile = file;
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
      _showAboveSheet = false;
      _showEmojiPicker = false;
    });
    ChatFieldV2.setEmojiShowing(false);

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _recordingStartedAt;
      if (startedAt == null || !mounted) return;
      setState(() {
        _recordingDuration = DateTime.now().difference(startedAt);
      });
    });
  }

  Future<void> _stopAndSendRecording() async {
    final startedAt = _recordingStartedAt;
    final fallbackFile = _recordingFile;
    _recordingTimer?.cancel();

    final path = await _audioRecorder.stop();
    final duration = startedAt == null ? _recordingDuration : DateTime.now().difference(startedAt);

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingStartedAt = null;
      _recordingFile = null;
      _recordingDuration = Duration.zero;
    });

    final audioPath = path ?? fallbackFile?.path;
    if (audioPath == null || duration.inMilliseconds < 800) return;

    try {
      await widget.store.sendAudioMessage(
        audioFile: File(audioPath),
        duration: duration,
      );
    } catch (_) {
      Get.snackbar(
        AppTranslationKey.chat.tr,
        AppTranslationKey.voiceMessageSendFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.cancel();

    final file = _recordingFile;
    if (file != null && await file.exists()) {
      await file.delete();
    }

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingStartedAt = null;
      _recordingFile = null;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildRecordingBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            tooltip: AppTranslationKey.cancel.tr,
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
          Expanded(
            child: Container(
              height: 46.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(widget.textFieldRadius),
              ),
              child: Row(
                children: [
                  Container(
                    width: 9.r,
                    height: 9.r,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  10.horizontalSpace,
                  Text(
                    _formatRecordingDuration(_recordingDuration),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: Text(
                      AppTranslationKey.recording.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
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
              tooltip: AppTranslationKey.send.tr,
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _stopAndSendRecording,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = colorSchemeOf(context);
    final isDarkMode = isDarkModeOf(context);
    final textFieldFillColor = isDarkMode ? const Color(0xFF202C33) : Colors.white;

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
              if (_isRecording)
                _buildRecordingBar(colorScheme)
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
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
                            minLines: 1,
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
                              fillColor: textFieldFillColor,
                              hintText: widget.hintText.tr,
                              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(widget.textFieldRadius),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: widget.showEmogyIcon
                                  ? IconButton(
                                      icon: Icon(
                                        _showEmojiPicker ? Icons.keyboard_alt_outlined : widget.emojiIcon,
                                        color: colorScheme.onSurfaceVariant,
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
                                      icon: Icon(widget.attachmentIcon, color: colorScheme.onSurfaceVariant),
                                      onPressed: () => showAttachment(context),
                                    )
                                  : null,
                            ),
                            style: TextStyle(color: colorScheme.onSurface),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _hasText ? widget.sendIcon : Icons.mic,
                            color: Colors.white,
                          ),
                          onPressed: _hasText ? widget.onSendTap : _toggleRecording,
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
