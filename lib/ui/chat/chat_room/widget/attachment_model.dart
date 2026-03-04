import 'dart:io';
import 'package:flutter/material.dart';

class AttachmentConfig {
  final Function(List<File>)? onCameraFilesPicked;
  final Function(List<File>)? onGalleryFilesPicked;
  final Function(List<File>)? onAudioFilesPicked;
  final Function(List<File>)? onDocFilerPicked;
  final void Function(Map<String, dynamic>)? onContactPicked;

  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final Color iconBackgroundColor;

  final bool showCamera;
  final bool showGallery;
  final bool showAudio;
  final bool showDoc;
  final bool showContact;

  const AttachmentConfig({
    this.onCameraFilesPicked,
    this.onGalleryFilesPicked,
    this.onAudioFilesPicked,
    this.onDocFilerPicked,
    this.onContactPicked,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.textColor = Colors.black,
    this.iconBackgroundColor = const Color(0xFFE0E0E0),
    this.showCamera = true,
    this.showGallery = true,
    this.showAudio = true,
    this.showDoc = true,
    this.showContact = true,
  });
}
